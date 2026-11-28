// Trocea un mensaje en piezas que quepan CADA UNA en un solo SMS, para enviarlas
// con sendTextMessage (isMultipart:false) — la única vía que NO toca
// getGroupIdLevel1 / READ_PHONE_STATE en Android 17/GrapheneOS (issue #12).
//
// Reglas:
//  - Empaqueta líneas enteras (\n) mientras quepan; así conserva la estructura
//    del SOS (cabecera, enlace, extras) y el orden crítico-primero.
//  - Nunca parte un enlace ni una palabra a la fuerza: si una línea sola no cabe,
//    se trocea por espacios (los tokens —URLs incluidas— quedan intactos).
//  - Encoding-aware y CONSERVADOR: si una pieza lleva algún carácter fuera de
//    GSM 03.38 (emoji, á, cirílico), se trata como UCS-2 (límite 66 caracteres);
//    si no, GSM 7-bit (152 septetos: los caracteres de extensión ^{}\[~]|€
//    cuentan dos). Los márgenes (<160/<70) garantizan que sendTextMessage NO
//    auto-parta.
//  - Idioma-agnóstico: opera sobre caracteres, no sobre contenido.

const int _gsmLimit = 152; // septets; margin under 160 (153 with a concatenation header)
// 66, not 67: the oksigenia_sms plugin cuts UCS-2 text every 66 characters, and
// a 67-character piece would leave here whole and go out as two parts.
const int _ucs2Limit = 66;

// GSM 03.38: caracteres NO-ASCII que sí caben en GSM 7-bit y por tanto NO
// fuerzan UCS-2. Incluye ¡ ¿ ñ, umlauts alemanes, acento grave en minúscula + é/É,
// nórdicos y el euro. NO incluye á í ó ú (acento agudo salvo é), guiones largos,
// emojis, cirílico ni acentos polacos/portugueses raros → esos van a UCS-2
// (conservador).
final Set<int> _gsmExtra = "¡¿ñÑäöüÄÖÜßàèéìòùÉåÅøØæÆÇ€".runes.toSet();

// GSM 03.38 extension table: each of these travels as an escape plus the
// character, two septets. Counting them as one let a "152 character" part grow
// past the 153 septets of a concatenated segment; Android then builds no PDU
// and the whole SMS fails.
final Set<int> _gsmExtension = "^{}\\[~]|€".runes.toSet();

// UCS-2 si hay algún carácter no-ASCII que no sea GSM-extra. (ASCII siempre GSM.)
bool _isUcs2(String s) => s.runes.any((r) => r > 0x7F && !_gsmExtra.contains(r));

/// Septets [s] takes in the GSM 7-bit alphabet (extension characters count
/// double). Only meaningful for text that is not UCS-2.
int gsmSeptets(String s) {
  int n = 0;
  for (final r in s.runes) {
    n += _gsmExtension.contains(r) ? 2 : 1;
  }
  return n;
}

// What the SMS counts: septets in GSM, UTF-16 code units in UCS-2 (an emoji
// outside the BMP counts 2, as it does on the air).
bool _fits(String s) =>
    _isUcs2(s) ? s.length <= _ucs2Limit : gsmSeptets(s) <= _gsmLimit;

// The longest head of [s] that fits one SMS, never cutting a surrogate pair.
int _fittingPrefix(String s) {
  final bool ucs2 = _isUcs2(s);
  int used = 0;
  int i = 0;
  while (i < s.length) {
    final int unit = s.codeUnitAt(i);
    final bool pair = unit >= 0xD800 && unit <= 0xDBFF && i + 1 < s.length;
    final int width = pair ? 2 : 1;
    final int cost = ucs2 ? width : (_gsmExtension.contains(unit) ? 2 : 1);
    if (used + cost > (ucs2 ? _ucs2Limit : _gsmLimit)) break;
    used += cost;
    i += width;
  }
  return i == 0 ? 1 : i;
}

String _joinLine(String a, String b) => a.isEmpty ? b : '$a\n$b';
String _joinWord(String a, String b) => a.isEmpty ? b : '$a $b';

// Trocea una línea demasiado larga por espacios, sin romper tokens (URLs).
List<String> _splitLongLine(String line) {
  final out = <String>[];
  String cur = '';
  for (final word in line.split(' ')) {
    final candidate = _joinWord(cur, word);
    if (_fits(candidate)) {
      cur = candidate;
    } else {
      if (cur.isNotEmpty) out.add(cur);
      // Un token solo mayor que un SMS (extremadamente raro con coords cortas):
      // como último recurso se trocea por caracteres para no perder información.
      if (_fits(word)) {
        cur = word;
      } else {
        var rest = word;
        while (!_fits(rest)) {
          final int cut = _fittingPrefix(rest);
          out.add(rest.substring(0, cut));
          rest = rest.substring(cut);
        }
        cur = rest;
      }
    }
  }
  if (cur.isNotEmpty) out.add(cur);
  return out;
}

/// Divide [message] en la lista mínima de piezas que quepan cada una en un solo
/// SMS. Nunca devuelve una pieza que fuerce al sistema a auto-partir.
List<String> splitSmsSafely(String message) {
  final pieces = <String>[];
  String cur = '';
  void flush() { if (cur.isNotEmpty) { pieces.add(cur); cur = ''; } }

  for (final line in message.split('\n')) {
    final candidate = _joinLine(cur, line);
    if (_fits(candidate)) {
      cur = candidate;
      continue;
    }
    flush();
    if (_fits(line)) {
      cur = line;
      continue;
    }
    // Línea que por sí sola no cabe → trocear por palabras.
    for (final sub in _splitLongLine(line)) {
      if (_fits(_joinLine(cur, sub))) {
        cur = _joinLine(cur, sub);
      } else {
        flush();
        cur = sub;
      }
    }
  }
  flush();
  return pieces.isEmpty ? [message] : pieces;
}

// Capital letters with a grave accent are not in the GSM 03.38 default table
// (only the lower-case ones are). With one of them the radio switches the whole
// text to UCS-2 (67 characters per part); parts counted as GSM (152) then fail,
// and in French the default note «À L'AIDE !» did exactly that.
const Map<String, String> _nonGsmCapitals = {
  'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U',
};

/// [text] with the characters that silently break GSM-7 replaced by their base
/// letter. Apply it to every SMS body before counting parts or sending.
String gsmSafe(String text) {
  if (!text.runes.any((r) => r >= 0xC0 && r <= 0xD9)) return text;
  final b = StringBuffer();
  for (final ch in text.split('')) {
    b.write(_nonGsmCapitals[ch] ?? ch);
  }
  return b.toString();
}
