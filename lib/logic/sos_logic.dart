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
import 'package:oksigenia_sos/l10n/app_localizations.dart'; 

enum SOSStatus { ready, scanning, locationFixed, preAlert, sent, error }

class SOSLogic extends ChangeNotifier {
  SOSStatus _status = SOSStatus.ready;
  String _errorMessage = '';
  static const platform = MethodChannel('com.oksigenia.sos/sms');
  
  bool _isFallDetectionActive = false;
  bool _isInactivityMonitorActive = false;
  String? _emergencyContact;
  
  double _currentGForce = 1.0;
  DateTime _lastMovementTime = DateTime.now();
  
  Timer? _inactivityTimer;
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
  String? get emergencyContact => _emergencyContact;

  Future<void> init() async {
    await _loadSettings();
    await _checkPermissions();
    _startGForceMonitoring();
    _startPassiveGPS();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyContact = prefs.getString('emergency_contact');
    notifyListeners();
  }

  // Monitor Pasivo GPS (Semáforo)
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
    } catch (e) { print("Passive GPS Error: $e"); }
  }

  void _startGForceMonitoring() {
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
      .listen((AccelerometerEvent event) {
        double rawMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        _currentGForce = rawMagnitude / 9.81;

        // Sensibilidad de movimiento
        if ((_currentGForce > 1.2 || _currentGForce < 0.8)) {
           _lastMovementTime = DateTime.now();
        }
        
        // Detección de impacto (Sacudida para test o Caída real)
        if (_isFallDetectionActive && _currentGForce > 3.5 && (_status == SOSStatus.ready || _status == SOSStatus.locationFixed)) {
          _triggerPreAlert();
        }
        notifyListeners();
      }, onError: (e) => print("Sensor Error: $e"));
  }

  Future<void> _checkPermissions() async {
    await [Permission.location, Permission.sms, Permission.notification].request();
  }

  void openSettings(BuildContext context) => _showContactDialog(context);
  
  void openPrivacy(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.privacyTitle),
        content: SingleChildScrollView(child: Text(AppLocalizations.of(ctx)!.privacyPolicyContent)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
    ));
  }

  void openDonation(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("💎 Oksigenia FOSS"),
      content: const Text("Versión Libre y Open Source.\nSi esta herramienta te da seguridad, apóyanos."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR")),
        ElevatedButton(
          onPressed: () {
            launchURL("https://www.paypal.com/donate/?business=paypal@oksigenia.cc&currency_code=EUR");
            Navigator.pop(ctx);
          }, 
          child: const Text("PayPal")
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
        
        // TIEMPO DE INACTIVIDAD: 3600 segundos (1 HORA)
        if (DateTime.now().difference(_lastMovementTime).inSeconds > 3600) {
          _triggerPreAlert();
        }
      });
    } else {
      _inactivityTimer?.cancel();
      if (_status == SOSStatus.preAlert) cancelAlert();
    }
    notifyListeners();
  }

  void _triggerPreAlert() async {
    _gpsSubscription?.pause(); 
    
    try { await platform.invokeMethod('wakeScreen'); } catch(_) {}

    _status = SOSStatus.preAlert;
    _countdownSeconds = 60;
    _currentVolume = 0.2;
    notifyListeners();

    try {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setAudioContext(AudioContext(
           android: AudioContextAndroid(
             isSpeakerphoneOn: true, stayAwake: true, 
             contentType: AndroidContentType.sonification, 
             usageType: AndroidUsageType.alarm, 
             audioFocus: AndroidAudioFocus.gainTransient
           ),
           iOS: AudioContextIOS(category: AVAudioSessionCategory.playback)
        ));
        await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer!.play(AssetSource('sounds/alarm.mp3'), volume: _currentVolume);
    } catch(e) { print("Audio Panic: $e"); }
    
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
    try { 
      _audioPlayer?.stop(); 
      _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch(_) {}
  }

  Future<void> sendSOS() async {
    if (_emergencyContact == null || _emergencyContact!.isEmpty) return;
    
    _setStatus(SOSStatus.scanning);
    
    _isInactivityMonitorActive = false;
    _isFallDetectionActive = false;
    _inactivityTimer?.cancel();
    _gpsSubscription?.cancel();
    
    String msgBody = "🆘 SOS OKSIGENIA\nHelp!";
    
    try {
      final LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 10,
        forceLocationManager: true, timeLimit: const Duration(seconds: 10)
      );
      Position pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      _setStatus(SOSStatus.locationFixed);
      msgBody += "\nhttp://googleusercontent.com/maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } catch (e) {
      msgBody += "\n(GPS Unavailable - Hardware Timeout)";
    }

    try {
      final String result = await platform.invokeMethod('sendSMS', {
        "phone": _emergencyContact,
        "msg": msgBody
      });
      
      if (result == "OK") {
        _setStatus(SOSStatus.sent);
        await platform.invokeMethod('sleepScreen');
      } else {
        _setStatus(SOSStatus.error, "SMS Failed");
      }
    } catch (e) {
      _setStatus(SOSStatus.error, "SMS Error: $e");
    }
  }

  void _setStatus(SOSStatus s, [String? e]) { 
      _status = s; 
      if (e != null) _errorMessage = e; 
      notifyListeners(); 
  }

  void _showContactDialog(BuildContext context) {
    String initial = _emergencyContact ?? "";
    if (initial.isEmpty) {
      String code = View.of(context).platformDispatcher.locale.countryCode ?? "ES";
      Map<String, String> prefixes = {"ES":"+34", "FR":"+33", "PT":"+351", "DE":"+49", "US":"+1", "GB":"+44"};
      initial = prefixes[code] ?? "+";
    }
    final ctrl = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsTitle),
        content: TextField(controller: ctrl, keyboardType: TextInputType.phone, autofocus: true, decoration: InputDecoration(labelText: l10n.settingsLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.btnClose)),
          ElevatedButton(onPressed: () async {
            final p = await SharedPreferences.getInstance();
            await p.setString('emergency_contact', ctrl.text);
            _emergencyContact = ctrl.text;
            notifyListeners();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(l10n.settingsSave))
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gpsSubscription?.cancel();
    _inactivityTimer?.cancel();
    _preAlertTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}