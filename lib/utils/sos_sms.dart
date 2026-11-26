import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:oksigenia_sms/oksigenia_sms.dart';

import 'sms_splitter.dart';

/// How one SMS to one contact ended.
///
/// Only [sent] and [unconfirmed] mean the radio took it. [unconfirmed] is a
/// hand-off with no acknowledgement inside the timeout: counted as sent so it
/// is never sent twice.
enum SosSmsOutcome { sent, unconfirmed, noNetwork, heldByLimit, failed }

bool sosSmsDelivered(SosSmsOutcome o) =>
    o == SosSmsOutcome.sent || o == SosSmsOutcome.unconfirmed;

/// Failures worth trying again later: no coverage, or a radio error. Never the
/// SMS limit: retrying would only queue more SMS behind the same system dialog.
bool sosSmsRetryable(SosSmsOutcome o) =>
    o == SosSmsOutcome.noNetwork || o == SosSmsOutcome.failed;

// Without coverage Android answers at once and keeps nothing: sending the same
// text in pieces would fail the same way, and each try counts against the
// per-app SMS limit.
const Set<String> _noNetworkErrors = {'no_service', 'radio_off'};

/// Sends [message] to [to] and says honestly how it ended.
///
/// Primary path: the own plugin, one concatenated SMS with a real result code.
/// On a radio error other than "no coverage", the text is sent in pieces that
/// each fit one SMS, every piece also through the plugin so its result is real.
/// The blind path (another_telephony, no acknowledgement) is only used when the
/// plugin itself is unavailable.
///
/// With [overLimit] the send goes past Android's per-app SMS limit, which holds
/// it behind an «Allow / Deny» dialog with no timeout: without an
/// acknowledgement it does not count as sent (#13).
Future<SosSmsOutcome> sendSosSms(
  String to,
  String message, {
  required bool overLimit,
  required Telephony telephony,
  required void Function(String) log,
}) async {
  final String body = gsmSafe(message);
  final Duration ackTimeout = Duration(seconds: overLimit ? 8 : 20);
  OksigeniaSmsResult r;
  try {
    r = await OksigeniaSms.send(to: to, message: body, timeout: ackTimeout)
        .timeout(ackTimeout + const Duration(seconds: 10));
  } catch (e) {
    log("SMS: plugin unavailable ($e) → blind pieces");
    return _blindPieces(to, body, overLimit: overLimit, telephony: telephony, log: log);
  }

  switch (r.status) {
    case OksigeniaSmsStatus.sent:
      log("SMS: sent (${r.okParts}/${r.parts})");
      return SosSmsOutcome.sent;
    case OksigeniaSmsStatus.unknown:
      if (overLimit) {
        log("SMS: held by Android's SMS limit (no acknowledgement)");
        return SosSmsOutcome.heldByLimit;
      }
      log("SMS: handed to the radio, no acknowledgement (${r.okParts}/${r.parts})");
      return SosSmsOutcome.unconfirmed;
    case OksigeniaSmsStatus.failed:
      if (overLimit || r.error == 'limit_exceeded') {
        log("SMS: Android's SMS limit (${r.error}), no pieces");
        return SosSmsOutcome.heldByLimit;
      }
      if (_noNetworkErrors.contains(r.error)) {
        log("SMS: no coverage (${r.error})");
        return SosSmsOutcome.noNetwork;
      }
      log("SMS: plugin failed (${r.error}) → acknowledged pieces");
      return _ackedPieces(to, body, telephony: telephony, log: log);
  }
}

// Each piece through the plugin, so its result is real. The first piece carries
// the header, the note and the location: it decides the outcome.
Future<SosSmsOutcome> _ackedPieces(
  String to,
  String body, {
  required Telephony telephony,
  required void Function(String) log,
}) async {
  final parts = splitSmsSafely(body);
  SosSmsOutcome first = SosSmsOutcome.failed;
  int ok = 0;
  for (int i = 0; i < parts.length; i++) {
    OksigeniaSmsResult r;
    try {
      r = await OksigeniaSms.send(
              to: to, message: parts[i], timeout: const Duration(seconds: 20))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      log("SMS: piece ${i + 1}/${parts.length} plugin error ($e)");
      if (i == 0) return SosSmsOutcome.failed;
      continue;
    }
    final SosSmsOutcome o = switch (r.status) {
      OksigeniaSmsStatus.sent => SosSmsOutcome.sent,
      OksigeniaSmsStatus.unknown => SosSmsOutcome.unconfirmed,
      OksigeniaSmsStatus.failed => _noNetworkErrors.contains(r.error)
          ? SosSmsOutcome.noNetwork
          : (r.error == 'limit_exceeded'
              ? SosSmsOutcome.heldByLimit
              : SosSmsOutcome.failed),
    };
    if (i == 0) first = o;
    if (sosSmsDelivered(o)) {
      ok++;
    } else {
      log("SMS: piece ${i + 1}/${parts.length} ${o.name} (${r.error})");
      // The first piece is the one that matters; after a coverage or limit
      // failure the rest would fail too, and each try costs SMS-limit budget.
      if (i == 0 || o == SosSmsOutcome.noNetwork || o == SosSmsOutcome.heldByLimit) break;
    }
  }
  log("SMS: pieces $ok/${parts.length}");
  return first;
}

// Legacy path, only when the plugin itself cannot be reached. No
// acknowledgement exists here, so success is "unconfirmed" at best.
Future<SosSmsOutcome> _blindPieces(
  String to,
  String body, {
  required bool overLimit,
  required Telephony telephony,
  required void Function(String) log,
}) async {
  final parts = splitSmsSafely(body);
  int ok = 0;
  for (int i = 0; i < parts.length; i++) {
    try {
      // another_telephony never answers when SEND_SMS is revoked: without a
      // timeout the whole SOS would hang here.
      await telephony
          .sendSms(to: to, message: parts[i], isMultipart: false)
          .timeout(const Duration(seconds: 20));
      ok++;
    } catch (e) {
      log("SMS: blind piece ${i + 1}/${parts.length} failed ($e)");
      if (i == 0) return SosSmsOutcome.failed;
    }
  }
  if (overLimit) return SosSmsOutcome.heldByLimit;
  return ok > 0 ? SosSmsOutcome.unconfirmed : SosSmsOutcome.failed;
}
