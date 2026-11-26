// Unit tests for the pure helpers behind the SOS: who gets it (phone numbers),
// whether it leaves (SMS encoding and splitting), what it says (texts) and
// what the log keeps. Each case is a bug found in the field or in a review.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oksigenia_sos/utils/beacon_fix.dart';
import 'package:oksigenia_sos/utils/geo_links.dart';
import 'package:oksigenia_sos/utils/inactivity_backstop.dart';
import 'package:oksigenia_sos/utils/phone_utils.dart';
import 'package:oksigenia_sos/utils/sentinel_log.dart';
import 'package:oksigenia_sos/utils/sms_budget.dart';
import 'package:oksigenia_sos/utils/sms_splitter.dart';
import 'package:oksigenia_sos/utils/sms_text.dart';

// GSM 03.38 default alphabet and extension table, as Android's GsmAlphabet.
const String _gsmDefault =
    '@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./0123456789:;<=>?'
    '¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà';
const String _gsmExt = '^{}\\[~]|€';

bool _isGsm7(String s) =>
    s.runes.every((r) => _gsmDefault.contains(String.fromCharCode(r)) ||
        _gsmExt.contains(String.fromCharCode(r)));

void main() {
  group('normalizePhoneE164', () {
    void check(String raw, String prefix, String expected) =>
        expect(normalizePhoneE164(raw, defaultPrefix: prefix), expected,
            reason: '"$raw" with $prefix');

    test('a prefilled prefix plus the national 0 drops the 0', () {
      check('+3306 12 34 56 78', '+33', '+33612345678');
      check('+44 (0)7700 900123', '+44', '+447700900123');
      check('+490171 1234567', '+49', '+491711234567');
      check('+3106 12345678', '+31', '+31612345678');
      check('+46070 123 45 67', '+46', '+46701234567');
      check('+353 087 123 4567', '+353', '+353871234567');
      check('0033 06 12 34 56 78', '+33', '+33612345678');
    });

    test('national numbers get the prefix, without their trunk 0', () {
      check('06 12 34 56 78', '+33', '+33612345678');
      check('070-123 45 67', '+46', '+46701234567');
      check('600 111 222', '+34', '+34600111222');
      check('4155550100', '+1', '+14155550100');
    });

    test('Italian mobiles and Brazilian area code 55 are not taken as prefixed', () {
      check('392 123 4567', '+39', '+393921234567');
      check('391 1234567', '+39', '+393911234567');
      check('(55) 99123-4567', '+55', '+5555991234567');
    });

    test('numbers already in international form stay as they are', () {
      check('+39 02 1234 5678', '+39', '+390212345678'); // Italy keeps its 0
      check('+34 600 111 222', '+34', '+34600111222');
      check('393921234567', '+39', '+393921234567');
      check('5511991234567', '+55', '+5511991234567');
      check('34600111222', '+34', '+34600111222');
    });
  });

  group('GSM 7-bit', () {
    test('capitals with a grave accent are transliterated', () {
      expect(gsmSafe("À L'AIDE ! È Ì Ò Ù"), "A L'AIDE ! E I O U");
      expect(gsmSafe('à è ì ò ù é É ñ'), 'à è ì ò ù é É ñ');
    });

    test('extension characters count two septets', () {
      expect(gsmSeptets('abc'), 3);
      expect(gsmSeptets('a|b'), 4);
      expect(gsmSeptets('€'), 2);
    });

    test('the default SOS of every language is priced on what is sent', () {
      final dir = Directory('lib/l10n');
      for (final f in dir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.arb'))) {
        final arb = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final note = arb['smsHelpMessage'] as String;
        final body = worstCaseSosBody(note);
        expect(body.contains('À'), isFalse, reason: f.path);
        // Languages whose note is Latin GSM text must stay in GSM 7-bit.
        if (_isGsm7(gsmSafe(note))) {
          expect(_isGsm7(body), isTrue, reason: f.path);
        }
      }
    });
  });

  group('splitSmsSafely', () {
    final String sos = gsmSafe('SOS OKSIGENIA\nÀ L\'AIDE ! Je suis tombé.\n'
        '${geoLinks(43.197521, -4.857334)}\n'
        '${sosTechLine(batteryPct: 63, altitudeM: 1834, accuracyM: 8, fixAgeSeconds: 900)}');

    test('every piece fits one SMS', () {
      for (final p in splitSmsSafely(sos)) {
        if (_isGsm7(p)) {
          expect(gsmSeptets(p), lessThanOrEqualTo(152), reason: p);
        } else {
          expect(p.length, lessThanOrEqualTo(66), reason: p);
        }
      }
    });

    test('no link is cut', () {
      final pieces = splitSmsSafely(sos);
      for (final link in ['geo:43.197521,-4.857334',
          'https://maps.google.com/?q=43.197521,-4.857334',
          'https://www.openstreetmap.org/?mlat=43.197521&mlon=-4.857334']) {
        expect(pieces.any((p) => p.contains(link)), isTrue, reason: link);
      }
    });
  });

  group('SMS texts', () {
    test('map links use a decimal point and six decimals, also negative', () {
      expect(geoLinks(-33.5, -70.25),
          contains('geo:-33.500000,-70.250000'));
    });

    test('the technical line has no "|" and says when the fix is old', () {
      final fresh = sosTechLine(batteryPct: 80, altitudeM: 12, accuracyM: 9, fixAgeSeconds: 10);
      final old = sosTechLine(batteryPct: 80, altitudeM: 12, accuracyM: 9, fixAgeSeconds: 720);
      expect(fresh.contains('|'), isFalse);
      expect(fresh.contains('min'), isFalse);
      expect(old, endsWith('12min'));
    });
  });

  group('log privacy', () {
    test('phone numbers are masked and positions cut to three decimals', () {
      expect(maskPhone('+34600111222'), '+34•••222');
      final line = scrubLogLine('SMS to +34 600 111 222 at 43.1975213,-4.8573341');
      expect(line.contains('600 111'), isFalse);
      expect(line, contains('43.197,-4.857'));
    });
  });

  group('beacon', () {
    test('only accurate and recent fixes can decide a move', () {
      expect(beaconFixUsable(accuracyM: 12, ageSeconds: 5), isTrue);
      expect(beaconFixUsable(accuracyM: 350, ageSeconds: 5), isFalse);
      expect(beaconFixUsable(accuracyM: 12, ageSeconds: 600), isFalse);
      expect(beaconFixUsable(accuracyM: 0, ageSeconds: 5), isFalse);
    });

    test('300 m is measured as about 300 m', () {
      final d = metersBetween(43.0, -4.0, 43.0 + 300 / 111195.0, -4.0);
      expect(d, closeTo(300, 1));
    });
  });

  group('inactivity backstop', () {
    test('fires after the service own limit, never before', () {
      final last = DateTime(2026, 11, 26, 10, 0, 0);
      final due = backstopDue(lastMovement: last, limitSeconds: 3600, now: last);
      expect(due.isAfter(last.add(const Duration(seconds: 3600))), isTrue);
    });
  });
}
