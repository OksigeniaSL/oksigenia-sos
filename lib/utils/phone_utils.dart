import 'dart:ui';

// US/CA carriers silently drop A2P SMS to non-E.164 numbers — Mel's
// non-primary recipients showed "sent" in her local SMS log but never
// reached destinations. Normalize defensively at send time.
const Map<String, String> _countryPrefixes = {
  'ES': '+34', 'FR': '+33', 'PT': '+351', 'DE': '+49', 'IT': '+39',
  'GB': '+44', 'UK': '+44', 'IE': '+353',
  'US': '+1', 'CA': '+1', 'MX': '+52',
  'AR': '+54', 'CO': '+57', 'CL': '+56', 'PE': '+51', 'BR': '+55',
  'NL': '+31', 'BE': '+32', 'LU': '+352',
  'SE': '+46', 'NO': '+47', 'DK': '+45', 'FI': '+358',
  'CH': '+41', 'AT': '+43', 'PL': '+48', 'CZ': '+420',
  'AU': '+61', 'NZ': '+64', 'JP': '+81',
};

String? _detectDefaultPrefix() {
  final cc = (PlatformDispatcher.instance.locale.countryCode ?? '').toUpperCase();
  return _countryPrefixes[cc];
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

  final prefix = defaultPrefix ?? _detectDefaultPrefix();
  if (prefix == null) return digits;

  // North America: 10-digit local or 11-digit with leading 1 → +1XXXXXXXXXX.
  if (prefix == '+1') {
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    if (digits.length == 10) return '+1$digits';
  }

  return '$prefix$digits';
}
