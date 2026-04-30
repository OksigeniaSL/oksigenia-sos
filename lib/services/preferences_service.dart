import 'package:shared_preferences/shared_preferences.dart';
import '../logic/activity_profile.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  // Claves
  static const String _keyContacts = 'emergency_contacts';
  static const String _keySosMessage = 'custom_message';
  static const String _keyInactivityTime = 'inactivity_time';
  static const String _keyUpdateInterval = 'update_interval';
  
  // NUEVAS CLAVES (Antiamnesia)
  static const String _keyFallDetection = 'fall_detection_enabled';
  static const String _keyInactivityMonitor = 'inactivity_monitor_enabled';
  
  // CLAVES RECUPERADAS (Idioma y Tema)
  static const String _keyLanguage = 'language_code';
  static const String _keyDarkMode = 'dark_mode';

  // LIVE TRACKING
  static const String _keyLiveTrackingEnabled = 'live_tracking_enabled';
  static const String _keyLiveTrackingInterval = 'live_tracking_interval_minutes';
  static const String _keyLiveTrackingShutdown = 'live_tracking_shutdown_minutes';

  // ACTIVITY PROFILE (v4.0.0)
  static const String _keyActivityProfile = 'activity_profile';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- CONTACTOS ---
  List<String> getContacts() {
    return _prefs?.getStringList(_keyContacts) ?? [];
  }

  // Método interno para guardar la lista
  Future<void> _saveContactsList(List<String> contacts) async {
    await _prefs?.setStringList(_keyContacts, contacts);
  }

  // Métodos antiguos (MANTENIDOS)
  Future<void> addContact(String number) async {
    List<String> current = getContacts();
    if (!current.contains(number)) {
      current.add(number);
      await _saveContactsList(current);
    }
  }

  Future<void> removeContact(String number) async {
    List<String> current = getContacts();
    current.remove(number);
    await _saveContactsList(current);
  }

  // Método NUEVO que pide settings_screen (Guardar lista completa)
  Future<void> saveContacts(List<String> contacts) async {
    await _saveContactsList(contacts);
  }

  // --- MENSAJE ---
  String getSosMessage() {
    return _prefs?.getString(_keySosMessage) ?? '';
  }

  // Alias para compatibilidad con settings_screen
  Future<void> saveSosMessage(String msg) async {
    await _prefs?.setString(_keySosMessage, msg);
  }
  
  // Mantenemos tu método set por si acaso
  Future<void> setSosMessage(String msg) async {
    await saveSosMessage(msg);
  }

  // --- TIEMPOS ---
  int getInactivityTime() {
    return _prefs?.getInt(_keyInactivityTime) ?? 3600;
  }

  // Alias para compatibilidad
  Future<void> saveInactivityTime(int seconds) async {
    await _prefs?.setInt(_keyInactivityTime, seconds);
  }

  Future<void> setInactivityTime(int seconds) async {
    await saveInactivityTime(seconds);
  }

  int getUpdateInterval() {
    return _prefs?.getInt(_keyUpdateInterval) ?? 0;
  }

  // Alias para compatibilidad
  Future<void> saveUpdateInterval(int minutes) async {
    await _prefs?.setInt(_keyUpdateInterval, minutes);
  }
  
  Future<void> setUpdateInterval(int minutes) async {
    await saveUpdateInterval(minutes);
  }

  // --- ANTIAMNESIA (Nuevos para v3.8.0) ---

  bool getFallDetectionState() {
    return _prefs?.getBool(_keyFallDetection) ?? false;
  }

  Future<void> saveFallDetectionState(bool isEnabled) async {
    await _prefs?.setBool(_keyFallDetection, isEnabled);
    // print("💾 Memoria: Caídas guardado como $isEnabled");
  }

  bool getInactivityState() {
    return _prefs?.getBool(_keyInactivityMonitor) ?? false;
  }

  Future<void> saveInactivityState(bool isEnabled) async {
    await _prefs?.setBool(_keyInactivityMonitor, isEnabled);
    // print("💾 Memoria: Inactividad guardado como $isEnabled");
  }

  // --- IDIOMA Y TEMA (RECUPERADOS) ---
  
  String getLanguage() {
    return _prefs?.getString(_keyLanguage) ?? 'es';
  }

  Future<void> saveLanguage(String langCode) async {
    await _prefs?.setString(_keyLanguage, langCode);
  }

  bool getDarkMode() {
    return _prefs?.getBool(_keyDarkMode) ?? false;
  }

  Future<void> saveDarkMode(bool isDark) async {
    await _prefs?.setBool(_keyDarkMode, isDark);
  }

  // --- LIVE TRACKING ---
  bool getLiveTrackingEnabled() => _prefs?.getBool(_keyLiveTrackingEnabled) ?? false;
  Future<void> setLiveTrackingEnabled(bool v) async => await _prefs?.setBool(_keyLiveTrackingEnabled, v);

  int getLiveTrackingIntervalMinutes() => _prefs?.getInt(_keyLiveTrackingInterval) ?? 30;
  Future<void> setLiveTrackingIntervalMinutes(int v) async => await _prefs?.setInt(_keyLiveTrackingInterval, v);

  int getLiveTrackingShutdownMinutes() => _prefs?.getInt(_keyLiveTrackingShutdown) ?? 0;
  Future<void> setLiveTrackingShutdownMinutes(int v) async => await _prefs?.setInt(_keyLiveTrackingShutdown, v);

  // --- ACTIVITY PROFILE ---
  ActivityProfile getActivityProfile() {
    return activityProfileFromName(_prefs?.getString(_keyActivityProfile));
  }

  Future<void> saveActivityProfile(ActivityProfile profile) async {
    await _prefs?.setString(_keyActivityProfile, profile.name);
  }
}