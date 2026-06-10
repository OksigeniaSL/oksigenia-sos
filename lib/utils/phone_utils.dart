import 'dart:ui';

// US/CA carriers silently drop A2P SMS to non-E.164 numbers — Mel's
// non-primary recipients showed "sent" in her local SMS log but never
// reached destinations. Normalize defensively at send time.
const Map<String, String> countryPrefixes = {
  'ES': '+34', 'FR': '+33', 'PT': '+351', 'DE': '+49', 'IT': '+39',
  'GB': '+44', 'UK': '+44', 'IE': '+353',
  'US': '+1', 'CA': '+1', 'MX': '+52',
  'AR': '+54', 'CO': '+57', 'CL': '+56', 'PE': '+51', 'BR': '+55',
  'NL': '+31', 'BE': '+32', 'LU': '+352',
  'SE': '+46', 'NO': '+47', 'DK': '+45', 'FI': '+358',
  'CH': '+41', 'AT': '+43', 'PL': '+48', 'CZ': '+420',
  'AU': '+61', 'NZ': '+64', 'JP': '+81',
};

// Países cuyo formato nacional antepone un 0 troncal que NO forma parte del
// número E.164 (FR `06 12 34 56 78` → `+33612345678`). Sin esto, anteponer el
// prefijo a un número nacional producía `+330612...`, que la operadora
// descarta en silencio — la misma clase de fallo que el bug de Mel.
// Italia (+39) se excluye a propósito: su 0 de fijos SÍ se conserva en E.164.
const Set<String> _trunkZeroPrefixes = {
  '+33', '+44', '+353', '+49', '+31', '+32', '+352',
  '+358', '+41', '+43', '+61', '+64', '+81', '+55', '+54',
};

String? detectDefaultPrefix() {
  final cc = (PlatformDispatcher.instance.locale.countryCode ?? '').toUpperCase();
  return countryPrefixes[cc];
}

String normalizePhoneE164(String raw, {String? defaultPrefix}) {
  String s = raw.trim();
  if (s.isEmpty) return s;

  if (s.startsWith('+')) {
    return '+${s.substring(1).replaceAll(RegExp(r'\D'), '')}';
  }

  if (s.startsWith('00')) {
    return '+${s.substring(2).replaceAll(RegExp(r'\D'), '')}';
  }

  final digits = s.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return s;

  final prefix = defaultPrefix ?? detectDefaultPrefix();
  if (prefix == null) return digits;

  // North America: 10-digit local or 11-digit with leading 1 → +1XXXXXXXXXX.
  if (prefix == '+1') {
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    if (digits.length == 10) return '+1$digits';
  }

  // Código de país ya tecleado pero sin '+' (p.ej. `34600111222` en España):
  // anteponer el prefijo otra vez daría `+3434600111222`. Los nacionales con
  // 0 troncal no pueden confundirse (empiezan por 0) y la longitud mínima
  // cc+8 evita falsos positivos con números cortos.
  final String ccDigits = prefix.substring(1);
  if (!digits.startsWith('0') &&
      digits.startsWith(ccDigits) &&
      digits.length >= ccDigits.length + 8) {
    return '+$digits';
  }

  String national = digits;
  if (_trunkZeroPrefixes.contains(prefix) && national.startsWith('0')) {
    national = national.substring(1);
  }

  return '$prefix$national';
}
