import 'dart:async';
import 'dart:math';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart'; 
import '../services/preferences_service.dart';
import '../screens/settings_screen.dart';  
import '../screens/alarm_screen.dart';
import '../screens/sent_screen.dart';  
import '../screens/home_screen.dart'; 

final GlobalKey<NavigatorState> oksigeniaNavigatorKey = GlobalKey<NavigatorState>();

enum SOSStatus { ready, scanning, locationFixed, preAlert, sent, error }
enum AlertCause { manual, fall, inactivity, dyingGasp }

class SOSLogic extends ChangeNotifier with WidgetsBindingObserver {
  SOSStatus _status = SOSStatus.ready;
  String _errorMessage = '';
  static const platform = MethodChannel('com.oksigenia.sos/sms');
  
  static const double _impactThreshold = 12.0;

  bool _isFallDetectionActive = false;
  bool _isDyingGaspSent = false; 
  bool _isInactivityMonitorActive = false;
  
  AlertCause _lastTrigger = AlertCause.manual;
  AlertCause get lastTrigger => _lastTrigger;

  int _currentInactivityLimit = 3600; 
  int get currentInactivityLimit => _currentInactivityLimit;

  double _visualGForce = 1.0;
  DateTime _lastMovementTime = DateTime.now();
  
  DateTime _lastSensorPacket = DateTime.now();
  bool _isWarmingUp = false;

  Timer? _inactivityTimer;
  Timer? _periodicUpdateTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gpsSubscription;
  
  int _batteryLevel = 0;
  double _gpsAccuracy = 0.0;
  Timer? _healthCheckTimer;
  
  bool _sensorsPermissionOk = true;
  bool _batteryOptimizationOk = true;
  
  bool _smsPermissionOk = true;
  bool _notificationPermissionOk = true;
  
  int get batteryLevel => _batteryLevel;
  double get gpsAccuracy => _gpsAccuracy;
  bool get sensorsPermissionOk => _sensorsPermissionOk;
  bool get batteryOptimizationOk => _batteryOptimizationOk;
  bool get smsPermissionOk => _smsPermissionOk;
  bool get notificationPermissionOk => _notificationPermissionOk;

  Timer? _preAlertTimer;
  int _countdownSeconds = 30; 
  int get currentCountdownSeconds => _countdownSeconds; 
  
  AudioPlayer? _audioPlayer; 
  final Battery _battery = Battery();

  SOSStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isFallDetectionActive => _isFallDetectionActive;
  bool get isInactivityMonitorActive => _isInactivityMonitorActive;
  
  double get currentGForce => _visualGForce;
  
  String? get emergencyContact {
    final contacts = PreferencesService().getContacts();
    return contacts.isNotEmpty ? contacts.first : null;
  }

  Future<void> init() async {
    if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) {
      return; 
    }

    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    
    await _loadSettings();
    await _checkPermissions(); 
    
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
    }

    _startGForceMonitoring();
    _startHealthMonitor(); 
    _startPassiveGPS();
    _updateSylviaStatus();
  }

  Future<bool> arePermissionsRestricted() async {
    bool smsRestricted = await Permission.sms.isPermanentlyDenied;
    bool locRestricted = await Permission.location.isPermanentlyDenied;
    return smsRestricted || locRestricted;
  }

  void _startHealthMonitor() {
    _checkHealth();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkHealth());
  }

  Future<void> _checkHealth() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      
      _smsPermissionOk = await Permission.sms.isGranted;
      _notificationPermissionOk = await Permission.notification.isGranted;

      if (_isWarmingUp) {
        _sensorsPermissionOk = true;
      } else {
        bool permActivity = await Permission.activityRecognition.isGranted;
        if (!permActivity) {
           _sensorsPermissionOk = false;
        } else {
           if (_isFallDetectionActive || _isInactivityMonitorActive) {
              bool isSensorAlive = DateTime.now().difference(_lastSensorPacket).inSeconds < 5;
              _sensorsPermissionOk = isSensorAlive;
           } else {
              _sensorsPermissionOk = true; 
           }
        }
      }

      _batteryOptimizationOk = await Permission.ignoreBatteryOptimizations.isGranted;

      if (_status != SOSStatus.locationFixed) _gpsAccuracy = 0.0;
      
      bool isSystemArmed = _isFallDetectionActive || _isInactivityMonitorActive;
      if (_batteryLevel <= 5 && !_isDyingGaspSent && emergencyContact != null && isSystemArmed) {
        _triggerDyingGasp();
      }

      notifyListeners();
    } catch(e) { debugPrint("Health Check Error: $e"); }
  }

  Future<void> requestBatteryOptimizationIgnore() async {
     var status = await Permission.ignoreBatteryOptimizations.request();
     if (status.isGranted) {
       _batteryOptimizationOk = true;
       notifyListeners();
     } else {
       openAppSettings();
     }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) return;
      
      _startGForceMonitoring(); 
      _checkHealth();
      if (_status == SOSStatus.ready) _startPassiveGPS();
      
    } else if (state == AppLifecycleState.paused) {
      if (!_isInactivityMonitorActive && !_isFallDetectionActive) {
         _accelerometerSubscription?.cancel();
      }
    } else if (state == AppLifecycleState.detached) {
      // 🧟 ZOMBIE KILLER: Secuencia blindada
      
      // 1. Matamos servicio
      try {
        final service = FlutterBackgroundService();
        service.invoke("stopService");
      } catch (_) {}
      
      // 2. Liberamos recursos locales con seguridad
      try { _gpsSubscription?.cancel(); } catch(_) {}
      try { _accelerometerSubscription?.cancel(); } catch(_) {}
      try { _inactivityTimer?.cancel(); } catch(_) {}
      try { _healthCheckTimer?.cancel(); } catch(_) {}
      try { WakelockPlus.disable(); } catch(_) {}
    }
  }

  Future<void> _loadSettings() async {
    final prefs = PreferencesService();
    _currentInactivityLimit = prefs.getInactivityTime();
    
    bool hasContact = emergencyContact != null;
    bool savedFallState = prefs.getFallDetectionState();
    
    if (savedFallState && hasContact) {
      _isFallDetectionActive = true; 
    } else {
      _isFallDetectionActive = false;
      if (savedFallState) prefs.saveFallDetectionState(false);
    }
    
    bool savedInactivityState = prefs.getInactivityState();
    if (savedInactivityState && hasContact) {
      if (!_isInactivityMonitorActive) toggleInactivityMonitor(true); 
    } else {
      if (_isInactivityMonitorActive) toggleInactivityMonitor(false); 
      if (savedInactivityState) prefs.saveInactivityState(false);
    }

    if (_errorMessage == "NO_CONTACT") {
       if (hasContact || (!_isFallDetectionActive && !_isInactivityMonitorActive)) {
         _setStatus(SOSStatus.ready);
       }
    }
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    await _loadSettings();
    _updateSylviaStatus();
  }

  void _startPassiveGPS() async {
    await _gpsSubscription?.cancel();
    final LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true, 
        intervalDuration: const Duration(seconds: 5)
    );

    try {
      _gpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? position) {
            if (position != null) {
               _gpsAccuracy = position.accuracy; 
               if (_status == SOSStatus.ready) _setStatus(SOSStatus.locationFixed); 
               notifyListeners();
            }
          }, onError: (_) {
             if (_status == SOSStatus.locationFixed) _setStatus(SOSStatus.ready);
          });
    } catch (e) { debugPrint("Passive GPS Error: $e"); }
  }

  void _startGForceMonitoring() {
    _accelerometerSubscription?.cancel();
    double lastG = 1.0;

    try {
      _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((AccelerometerEvent event) {
          
          _lastSensorPacket = DateTime.now(); 

          double rawMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          double instantG = rawMagnitude / 9.81;

          if (instantG > _visualGForce) {
            _visualGForce = instantG; 
          } else {
            _visualGForce = (_visualGForce * 0.90) + (instantG * 0.10); 
          }

          double delta = (instantG - lastG).abs();
          lastG = instantG;

          if (delta > 0.15 || instantG > 1.15 || instantG < 0.85) {
             _lastMovementTime = DateTime.now();
          }

          if (_isFallDetectionActive && instantG > _impactThreshold && (_status == SOSStatus.ready || _status == SOSStatus.locationFixed)) {
            debugPrint("💥 IMPACTO: ${instantG.toStringAsFixed(2)} G");
            _triggerPreAlert(AlertCause.fall);
          }
          notifyListeners();
        }, onError: (e) => debugPrint("Sensor Error: $e"));
    } catch (e) { debugPrint("Error acelerómetro: $e"); }
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.location, 
      Permission.sms, 
      Permission.notification,
      Permission.activityRecognition 
    ].request();
  }

  void openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))
      .then((_) => refreshConfig());
  }
  
  void openPrivacy(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.privacyTitle),
        content: SingleChildScrollView(child: Text(AppLocalizations.of(ctx)!.privacyPolicyContent)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
    ));
  }

  void openDonation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(l10n.donateDialogTitle),
      content: Text(l10n.donateDialogBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.donateClose)),
        ElevatedButton(
          onPressed: () {
            launchURL("https://www.paypal.com/donate/?business=paypal@oksigenia.cc&currency_code=EUR");
            Navigator.pop(ctx);
          }, 
          child: Text(l10n.donateBtn)
        )
      ],
    ));
  }

  void launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void toggleFallDetection(bool value) async {
    if (value && emergencyContact == null) {
      _setStatus(SOSStatus.error, "NO_CONTACT"); 
      _isFallDetectionActive = false;
      notifyListeners();
      _updateSylviaStatus(); 
      return;
    }
    _isFallDetectionActive = value;
    if (value && _errorMessage == "NO_CONTACT") _setStatus(SOSStatus.ready); 
    
    if (value) {
      _isWarmingUp = true;
      _lastSensorPacket = DateTime.now(); 
      _sensorsPermissionOk = true; 
      
      Future.delayed(const Duration(seconds: 3), () {
        _isWarmingUp = false;
        notifyListeners();
      });

      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) service.startService();
    }
    PreferencesService().saveFallDetectionState(value);
    _updateSylviaStatus(); 
    notifyListeners();
  }

  void toggleInactivityMonitor(bool value) async {
    if (value && emergencyContact == null) {
      _setStatus(SOSStatus.error, "NO_CONTACT");
      _isInactivityMonitorActive = false;
      notifyListeners();
      _updateSylviaStatus(); 
      return;
    }
    _isInactivityMonitorActive = value;
    if (value && _errorMessage == "NO_CONTACT") _setStatus(SOSStatus.ready); 
    
    final service = FlutterBackgroundService();
    if (value) {
      if (!(await service.isRunning())) service.startService();
    }
    
    PreferencesService().saveInactivityState(value);
    _updateSylviaStatus(); 

    if (value) {
      _isWarmingUp = true;
      _lastSensorPacket = DateTime.now(); 
      _sensorsPermissionOk = true;
      _lastMovementTime = DateTime.now();

      Future.delayed(const Duration(seconds: 3), () {
        _isWarmingUp = false;
        notifyListeners();
      });
      
      _inactivityTimer?.cancel(); 
      _inactivityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_isInactivityMonitorActive) {
           timer.cancel();
           return;
        }
        if (_status != SOSStatus.ready && _status != SOSStatus.locationFixed) return;
        
        if (DateTime.now().difference(_lastMovementTime).inSeconds > _currentInactivityLimit) {
          debugPrint("💤 ALERTA: Inactividad detectada");
          _triggerPreAlert(AlertCause.inactivity);
        }
      });
    } else {
      _inactivityTimer?.cancel();
      if (_status == SOSStatus.preAlert && _lastTrigger == AlertCause.inactivity) {
        cancelAlert(); 
      }
    }
    notifyListeners();
  }

  void _triggerPreAlert(AlertCause cause) async {
    if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) return;

    debugPrint("SYLVIA: 🚨 ALARMA ACTIVADA");
    _lastTrigger = cause;
    _status = SOSStatus.preAlert;
    _countdownSeconds = 30; 
    _updateSylviaStatus(); 
    notifyListeners(); 

    _gpsSubscription?.pause(); 
    
    try {
       final service = FlutterBackgroundService();
       service.invoke("startAlarm"); 
       Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
    } catch (e) { debugPrint("Error servicio: $e"); }

    _preAlertTimer?.cancel();
    _preAlertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners(); 
      if (_countdownSeconds <= 0) {
        timer.cancel();
        sendSOS(); 
      }
    });

    try { await platform.invokeMethod('bringToFront'); } catch(_) {}

    await Future.delayed(const Duration(milliseconds: 500));
    if (oksigeniaNavigatorKey.currentState != null) {
      await oksigeniaNavigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AlarmScreen()),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _triggerDyingGasp() async {
    _isDyingGaspSent = true; 
    debugPrint("🪫 DYING GASP ACTIVADO");

    final prefs = PreferencesService();
    final List<String> recipients = prefs.getContacts();
    if (recipients.isEmpty) return;

    final sharedPrefs = await SharedPreferences.getInstance();
    String langCode = sharedPrefs.getString('language_code') ?? 'en';
    final t = await AppLocalizations.delegate.load(Locale(langCode));
    
    String msg = t.smsDyingGasp; 
    if (msg.isEmpty) msg = "⚠️ BATT <5%. Bye. Loc:"; 

    try {
      Position pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5))
        .catchError((_) async => await Geolocator.getLastKnownPosition() ?? Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0));

      msg += "\nhttp://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      
      for (String number in recipients) {
        await platform.invokeMethod('sendSMS', {"phone": number, "msg": msg});
      }
    } catch (e) { debugPrint("❌ Fallo Dying Gasp: $e"); }
  }

  void cancelAlert() => cancelSOS();

  void cancelSOS() {
    debugPrint("LOGIC: 🛑 Cancelado por usuario.");
    _preAlertTimer?.cancel();
    _preAlertTimer = null;
    _audioPlayer?.stop(); 
    try {
      final service = FlutterBackgroundService();
      service.invoke("stopAlarm");
      Vibration.cancel(); 
    } catch (e) { debugPrint("Error servicio: $e"); }

    if (_gpsSubscription != null && _gpsSubscription!.isPaused) _gpsSubscription!.resume();
    _lastMovementTime = DateTime.now();
    _setStatus(SOSStatus.ready);
    _countdownSeconds = 30; 
    
    if (_isInactivityMonitorActive) {
      toggleInactivityMonitor(false); 
      toggleInactivityMonitor(true);  
    }
    _updateSylviaStatus(); 
    notifyListeners();
  }

  void _stopAllAlerts() {
    _preAlertTimer?.cancel();
    _periodicUpdateTimer?.cancel();
    try { _audioPlayer?.stop(); _audioPlayer?.dispose(); _audioPlayer = null; } catch(_) {}
    try { Vibration.cancel(); } catch(_) {}
  }

  Future<void> sendSOS() async {
    final prefs = PreferencesService();
    final List<String> recipients = prefs.getContacts();
    final String customNote = prefs.getSosMessage();

    if (recipients.isEmpty) {
      _setStatus(SOSStatus.error, "NO_CONTACT");
      return;
    }
    
    _setStatus(SOSStatus.scanning);
    _inactivityTimer?.cancel();
    _gpsSubscription?.cancel();
    int batteryLevel = await _battery.batteryLevel;

    String msgBody = "🆘 SOS OKSIGENIA";
    if (customNote.isNotEmpty) {
      msgBody += "\n$customNote"; 
    } else {
      final sharedPrefs = await SharedPreferences.getInstance();
      String langCode = sharedPrefs.getString('language_code') ?? 'en';
      final t = await AppLocalizations.delegate.load(Locale(langCode));
      String helpText = t.smsHelpMessage; 
      if (helpText.isEmpty) helpText = "HELP!"; 
      msgBody += "\n$helpText"; 
    }
    
    try {
      final LocationSettings locationSettings = AndroidSettings(accuracy: LocationAccuracy.high, forceLocationManager: true, timeLimit: const Duration(seconds: 15));
      Position pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      _setStatus(SOSStatus.locationFixed);
      msgBody += "\nMaps: http://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
      msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${pos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${pos.accuracy.toStringAsFixed(0)}m";
    } catch (e) {
      msgBody += "\n(GPS Error/Timeout)";
      msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
    }

    int successCount = 0;
    for (String number in recipients) {
      try {
        final String result = await platform.invokeMethod('sendSMS', {"phone": number, "msg": msgBody});
        if (result == "OK") successCount++;
      } catch (e) { debugPrint("Error enviando: $e"); }
    }

    if (successCount > 0) {
      try {
        final service = FlutterBackgroundService();
        service.invoke("stopAlarm");
        Vibration.cancel(); 
      } catch (e) {}

      _setStatus(SOSStatus.sent);
      await platform.invokeMethod('sleepScreen');
      
      try {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setAudioContext(AudioContext(
           android: AudioContextAndroid(
               isSpeakerphoneOn: true, stayAwake: false, contentType: AndroidContentType.sonification, usageType: AndroidUsageType.media, audioFocus: AndroidAudioFocus.gainTransient
           ),
           iOS: AudioContextIOS(category: AVAudioSessionCategory.playback)
        ));
        await _audioPlayer!.setVolume(1.0); 
        await _audioPlayer!.play(AssetSource('sounds/send.mp3'));
      } catch(e) {}

      int interval = prefs.getUpdateInterval();
      if (interval > 0) _startPeriodicUpdates(interval, recipients);
    } else {
      _setStatus(SOSStatus.error, "Fallo SMS / SMS Failed");
    }
  }

  void _startPeriodicUpdates(int minutes, List<String> recipients) {
    if (recipients.isEmpty) return;
    String target = recipients.first; 
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = Timer.periodic(Duration(minutes: minutes), (timer) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 20));
        String updateMsg = "📍 SEGUIMIENTO Oksigenia: Sigo en ruta / Still moving.";
        updateMsg += "\nMaps: http://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        updateMsg += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        await platform.invokeMethod('sendSMS', {"phone": target, "msg": updateMsg});
      } catch (e) {}
    });
  }

  void _setStatus(SOSStatus s, [String? e]) { 
      _status = s; 
      if (s == SOSStatus.ready || s == SOSStatus.locationFixed) {
        _errorMessage = '';
      } else if (e != null) {
        _errorMessage = e; 
      }
      notifyListeners(); 
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSubscription?.cancel();
    _gpsSubscription?.cancel();
    _inactivityTimer?.cancel();
    _periodicUpdateTimer?.cancel();
    _healthCheckTimer?.cancel();
    _preAlertTimer?.cancel();
    _audioPlayer?.dispose();
    
    // ZOMBIE KILLER EXTRA
    try {
      final service = FlutterBackgroundService();
      service.invoke("stopService"); 
    } catch (_) {}
    
    super.dispose();
  }

  void _updateSylviaStatus() async {
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        bool isActive = _isFallDetectionActive || _isInactivityMonitorActive;
        final prefs = await SharedPreferences.getInstance(); 
        String lang = prefs.getString('language_code') ?? 'en';
        final t = await AppLocalizations.delegate.load(Locale(lang));

        String title = "";
        String content = "";
        String statusIcon = "active"; // Por defecto activo

        if (_status == SOSStatus.preAlert) {
          statusIcon = "alarm";
          title = "🚨 SOS"; 
          content = t.alertFallDetected; 
        } else if (!isActive) {
          // Si no hay nada activo, ponemos el icono de pausa
          statusIcon = "paused";
          title = t.statusMonitorStopped; 
          content = "---"; 
        } else {
          title = t.statusReady; 
          List<String> activeModes = [];
          if (_isFallDetectionActive) activeModes.add(t.autoModeLabel); 
          if (_isInactivityMonitorActive) activeModes.add(t.inactivityModeLabel); 
          content = activeModes.join(" + ");
        }

        service.invoke("updateNotification", {
          "status": statusIcon,
          "title": title,    
          "content": content 
        });
      }
    } catch (_) {
      // Silenciamos error si se llama desde un isolate muerto
    }
  }
}