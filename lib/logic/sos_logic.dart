import 'dart:async';
import 'dart:math';
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
import 'package:oksigenia_sos/l10n/app_localizations.dart'; 
import '../services/preferences_service.dart';
import '../screens/settings_screen.dart'; 

enum SOSStatus { ready, scanning, locationFixed, preAlert, sent, error }
enum AlertCause { manual, fall, inactivity }

class SOSLogic extends ChangeNotifier {
  SOSStatus _status = SOSStatus.ready;
  String _errorMessage = '';
  static const platform = MethodChannel('com.oksigenia.sos/sms');
  
  bool _isFallDetectionActive = false;
  bool _isInactivityMonitorActive = false;
  
  AlertCause _lastTrigger = AlertCause.manual;
  AlertCause get lastTrigger => _lastTrigger;

  int _currentInactivityLimit = 3600; 
  int get currentInactivityLimit => _currentInactivityLimit;

  double _currentGForce = 1.0;
  DateTime _lastMovementTime = DateTime.now();
  
  Timer? _inactivityTimer;
  Timer? _periodicUpdateTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gpsSubscription;
  
  Timer? _preAlertTimer;
  int _countdownSeconds = 60;
  
  AudioPlayer? _audioPlayer; 
  double _currentVolume = 0.2;

  SOSStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isFallDetectionActive => _isFallDetectionActive;
  bool get isInactivityMonitorActive => _isInactivityMonitorActive;
  int get countdownSeconds => _countdownSeconds;
  double get currentGForce => _currentGForce;
  
  String? get emergencyContact {
    final contacts = PreferencesService().getContacts();
    return contacts.isNotEmpty ? contacts.first : null;
  }

  Future<void> init() async {
    await _loadSettings();
    await _checkPermissions();
    // CORRECCIÓN: Pequeña pausa para asegurar que los sensores arrancan bien
    await Future.delayed(const Duration(milliseconds: 500));
    _startGForceMonitoring();
    _startPassiveGPS();
  }

  Future<void> _loadSettings() async {
    _currentInactivityLimit = PreferencesService().getInactivityTime();
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    _currentInactivityLimit = PreferencesService().getInactivityTime();
    if (_isInactivityMonitorActive) {
      toggleInactivityMonitor(false);
      toggleInactivityMonitor(true);
    }
    notifyListeners();
  }

  void _startPassiveGPS() async {
    final LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true, 
        intervalDuration: const Duration(seconds: 5)
    );

    try {
      _gpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? position) {
            if (_status == SOSStatus.ready && position != null) {
               _setStatus(SOSStatus.locationFixed); 
            }
          }, onError: (_) {
             if (_status == SOSStatus.locationFixed) _setStatus(SOSStatus.ready);
          });
    } catch (e) { debugPrint("Passive GPS Error: $e"); }
  }

  void _startGForceMonitoring() {
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
      .listen((AccelerometerEvent event) {
        double rawMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        _currentGForce = rawMagnitude / 9.81;

        if ((_currentGForce > 1.2 || _currentGForce < 0.8)) {
           _lastMovementTime = DateTime.now();
        }
        
        if (_isFallDetectionActive && _currentGForce > 3.5 && (_status == SOSStatus.ready || _status == SOSStatus.locationFixed)) {
          _triggerPreAlert(AlertCause.fall);
        }
        notifyListeners();
      }, onError: (e) => debugPrint("Sensor Error: $e"));
  }

  Future<void> _checkPermissions() async {
    await [Permission.location, Permission.sms, Permission.notification].request();
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

  void toggleFallDetection(bool value) {
    _isFallDetectionActive = value;
    notifyListeners();
  }

  void toggleInactivityMonitor(bool value) {
    _isInactivityMonitorActive = value;
    if (value) {
      _lastMovementTime = DateTime.now();
      _inactivityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_status != SOSStatus.ready && _status != SOSStatus.locationFixed) return;
        
        if (DateTime.now().difference(_lastMovementTime).inSeconds > _currentInactivityLimit) {
          _triggerPreAlert(AlertCause.inactivity);
        }
      });
    } else {
      _inactivityTimer?.cancel();
      if (_status == SOSStatus.preAlert) cancelAlert();
    }
    notifyListeners();
  }

  void _triggerPreAlert(AlertCause cause) async {
    _lastTrigger = cause;
    _gpsSubscription?.pause(); 
    try { await platform.invokeMethod('wakeScreen'); } catch(_) {}

    _status = SOSStatus.preAlert;
    _countdownSeconds = 60;
    _currentVolume = 0.2;
    notifyListeners();

    // 1. SONIDO
    try {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setAudioContext(AudioContext(
           android: AudioContextAndroid(isSpeakerphoneOn: true, stayAwake: true, contentType: AndroidContentType.sonification, usageType: AndroidUsageType.alarm, audioFocus: AndroidAudioFocus.gainTransient),
           iOS: AudioContextIOS(category: AVAudioSessionCategory.playback)
        ));
        await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer!.play(AssetSource('sounds/alarm.mp3'), volume: _currentVolume);
    } catch(e) { debugPrint("Audio Panic: $e"); }
    
    // 2. VIBRACIÓN (NUEVO) - Patrón intenso
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Vibra 500ms, para 500ms, repite indefinidamente (índice 0)
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
      }
    } catch (e) { debugPrint("Vibration Error: $e"); }

    _preAlertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        if (_currentVolume < 1.0 && _audioPlayer != null) {
          _currentVolume += 0.1;
          _audioPlayer!.setVolume(_currentVolume).catchError((_){});
        }
        notifyListeners();
      } else {
        _stopAllAlerts();    
        sendSOS();                
      }
    });
  }

  void cancelAlert() async {
    _stopAllAlerts();
    _status = SOSStatus.ready;
    _lastMovementTime = DateTime.now();
    _gpsSubscription?.resume();
    try { await platform.invokeMethod('sleepScreen'); } catch(_) {}
    notifyListeners();
  }

  void _stopAllAlerts() {
    _preAlertTimer?.cancel();
    _periodicUpdateTimer?.cancel();
    // DETENER AUDIO Y VIBRACIÓN
    try { _audioPlayer?.stop(); _audioPlayer?.dispose(); _audioPlayer = null; } catch(_) {}
    try { Vibration.cancel(); } catch(_) {}
  }

  Future<void> sendSOS() async {
    final prefs = PreferencesService();
    final List<String> recipients = prefs.getContacts();
    final String customNote = prefs.getSosMessage();

    if (recipients.isEmpty) {
      _setStatus(SOSStatus.error, "No contacts / Sin contactos");
      return;
    }
    
    _setStatus(SOSStatus.scanning);
    _isInactivityMonitorActive = false;
    _isFallDetectionActive = false;
    _inactivityTimer?.cancel();
    _gpsSubscription?.cancel();
    
    String msgBody = "🆘 SOS OKSIGENIA";
    if (customNote.isNotEmpty) {
      msgBody += "\n$customNote"; 
    } else {
      msgBody += "\n¡AYUDA / HELP!"; 
    }
    
    try {
      final LocationSettings locationSettings = AndroidSettings(accuracy: LocationAccuracy.high, forceLocationManager: true, timeLimit: const Duration(seconds: 15));
      Position pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      _setStatus(SOSStatus.locationFixed);
      // CORRECCIÓN DEFINITIVA: ISSUE #1 & OSM (Sin typos, con $)
      // Google: Formato corto y seguro (HTTPS) que invoca la App.
      msgBody += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      // OSM: Enlace web universal.
      msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
    } catch (e) {
      msgBody += "\n(GPS Error/Timeout)";
    }

    int successCount = 0;
    for (String number in recipients) {
      try {
        final String result = await platform.invokeMethod('sendSMS', {"phone": number, "msg": msgBody});
        if (result == "OK") successCount++;
      } catch (e) { debugPrint("Error enviando: $e"); }
    }

    if (successCount > 0) {
      _setStatus(SOSStatus.sent);
      await platform.invokeMethod('sleepScreen');
      
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
        // CORRECCIÓN DEFINITIVA EN UPDATES TAMBIÉN
        String updateMsg = "📍 SEGUIMIENTO Oksigenia: Sigo en ruta / Still moving.";
        updateMsg += "\nMaps: http://googleusercontent.com/maps.google.com/?q=${pos.latitude},${pos.longitude}";
        updateMsg += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        await platform.invokeMethod('sendSMS', {"phone": target, "msg": updateMsg});
      } catch (e) { debugPrint("❌ Fallo update: $e"); }
    });
  }

  void _setStatus(SOSStatus s, [String? e]) { 
      _status = s; 
      if (e != null) _errorMessage = e; 
      notifyListeners(); 
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gpsSubscription?.cancel();
    _inactivityTimer?.cancel();
    _periodicUpdateTimer?.cancel();
    _preAlertTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}