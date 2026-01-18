import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _kContactsList = 'sos_contacts_list';
  static const String _kOldSingleContact = 'target_phone'; 
  static const String _kCustomMessage = 'sos_custom_message';
  static const String _kDefaultMessage = "SOS! Necesito ayuda. Estas son mis coordenadas:";
  static const String _kUpdateInterval = 'sos_update_interval';
  static const String _kInactivityTime = 'sos_inactivity_time'; // NUEVO

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateOldData();
  }

  Future<void> _migrateOldData() async {
    if (_prefs.containsKey(_kOldSingleContact) && !_prefs.containsKey(_kContactsList)) {
      String? oldPhone = _prefs.getString(_kOldSingleContact);
      if (oldPhone != null && oldPhone.isNotEmpty) {
        await _prefs.setStringList(_kContactsList, [oldPhone]);
      }
    }
  }

  // --- CONTACTOS ---
  List<String> getContacts() {
    return _prefs.getStringList(_kContactsList) ?? [];
  }

  Future<void> addContact(String number) async {
    List<String> current = getContacts();
    if (!current.contains(number)) {
      current.add(number);
      await _prefs.setStringList(_kContactsList, current);
    }
  }

  Future<void> removeContact(String number) async {
    List<String> current = getContacts();
    current.remove(number);
    await _prefs.setStringList(_kContactsList, current);
  }

  // --- MENSAJE ---
  String getSosMessage() {
    return _prefs.getString(_kCustomMessage) ?? _kDefaultMessage;
  }

  Future<void> setSosMessage(String message) async {
    if (message.trim().isEmpty) {
      await _prefs.remove(_kCustomMessage);
    } else {
      await _prefs.setString(_kCustomMessage, message);
    }
  }

  // --- INTERVALO DE ACTUALIZACIÓN (TRACKING) ---
  int getUpdateInterval() {
    return _prefs.getInt(_kUpdateInterval) ?? 0;
  }

  Future<void> setUpdateInterval(int minutes) async {
    await _prefs.setInt(_kUpdateInterval, minutes);
  }

  // --- TIEMPO DE INACTIVIDAD (NUEVO) ---
  // Por defecto 3600 segundos (1 hora)
  int getInactivityTime() {
    return _prefs.getInt(_kInactivityTime) ?? 3600;
  }

  Future<void> setInactivityTime(int seconds) async {
    await _prefs.setInt(_kInactivityTime, seconds);
  }
}