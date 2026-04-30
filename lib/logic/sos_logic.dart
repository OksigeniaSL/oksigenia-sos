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
import 'package:vibration/vibration.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart'; 
import 'package:another_telephony/telephony.dart';
import 'activity_profile.dart';
import '../services/preferences_service.dart';
import '../screens/settings_screen.dart';  
import '../screens/alarm_screen.dart';
import '../screens/sent_screen.dart';
import '../screens/home_screen.dart';

final GlobalKey<NavigatorState> oksigeniaNavigatorKey = GlobalKey<NavigatorState>();

enum SOSStatus { ready, scanning, locationFixed, preAlert, sent, error }
enum AlertCause { manual, fall, inactivity, dyingGasp }
enum SentinelState { green, yellow, orange, red }

class SOSLogic extends ChangeNotifier with WidgetsBindingObserver {
  SOSStatus _status = SOSStatus.ready;
  String _errorMessage = '';
  static const platform = MethodChannel('com.oksigenia.sos/sms');
  final Telephony _telephony = Telephony.instance;

  bool _isFallDetectionActive = false;
  bool _isDyingGaspSent = false;
  bool _isInactivityMonitorActive = false;
  DateTime? _pausedUntil;
  int _pauseFrozenElapsed = 0;

  bool _isLiveTrackingActive = false;
  DateTime? _liveTrackingNextSend;
  int _liveTrackingIntervalMinutes = 30;
  
  bool _uiCooldown = false;
  bool _ignoreSensors = true;
  bool _sentinelYellow = false;
  bool _sentinelOrange = false;
  
  AlertCause _lastTrigger = AlertCause.manual;
  AlertCause get lastTrigger => _lastTrigger;

  int _currentInactivityLimit = 3600; 
  int get currentInactivityLimit => _currentInactivityLimit;

  double _visualGForce = 1.0;
  DateTime _lastMovementTime = DateTime.now();
  
  DateTime _lastSensorPacket = DateTime.now();
  bool _isWarmingUp = false;
  DateTime _lastCancellationTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _inactivityTimer;
  Timer? _periodicUpdateTimer;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gpsSubscription;
  
  int _batteryLevel = 0;
  double _gpsAccuracy = 0.0;
  Timer? _healthCheckTimer;
  
  bool _sensorsPermissionOk = true;
  bool _batteryOptimizationOk = true;
  bool _fullScreenIntentOk = true;

  bool _smsPermissionOk = true;
  bool _notificationPermissionOk = true;

  int get batteryLevel => _batteryLevel;
  double get gpsAccuracy => _gpsAccuracy;
  bool get sensorsPermissionOk => _sensorsPermissionOk;
  bool get batteryOptimizationOk => _batteryOptimizationOk;
  bool get fullScreenIntentOk => _fullScreenIntentOk;
  bool get smsPermissionOk => _smsPermissionOk;
  bool get notificationPermissionOk => _notificationPermissionOk;
  int get inactivityElapsedSeconds => isMonitoringPaused
      ? _pauseFrozenElapsed
      : DateTime.now().difference(_lastMovementTime).inSeconds;

  Timer? _preAlertTimer;
  int _countdownSeconds = 30; 
  int get currentCountdownSeconds => _countdownSeconds; 
  
  AudioPlayer? _audioPlayer; 
  final Battery _battery = Battery();

  SOSStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isFallDetectionActive => _isFallDetectionActive;
  bool get isInactivityMonitorActive => _isInactivityMonitorActive;
  bool get isMonitoringPaused => _pausedUntil != null && _pausedUntil!.isAfter(DateTime.now());
  int get pauseRemainingSeconds => _pausedUntil != null ? max(0, _pausedUntil!.difference(DateTime.now()).inSeconds) : 0;

  bool get isLiveTrackingActive => _isLiveTrackingActive;
  int get liveTrackingIntervalMinutes => _liveTrackingIntervalMinutes;
  int get liveTrackingNextSendSeconds => _liveTrackingNextSend != null
      ? max(0, _liveTrackingNextSend!.difference(DateTime.now()).inSeconds)
      : 0;

  double get currentGForce => _visualGForce;

  SentinelState get sentinelState {
    if (_status == SOSStatus.sent) return SentinelState.red;
    if (_status == SOSStatus.preAlert) return SentinelState.red;
    if (_sentinelOrange) return SentinelState.orange;
    if (_sentinelYellow) return SentinelState.yellow;
    return SentinelState.green;
  }

  Color get sentinelColor {
    switch (sentinelState) {
      case SentinelState.yellow: return Colors.amber;
      case SentinelState.orange: return Colors.orange;
      case SentinelState.red: return Colors.red;
      case SentinelState.green: return Colors.green;
    }
  }
  
  String? get emergencyContact {
    final contacts = PreferencesService().getContacts();
    return contacts.isNotEmpty ? contacts.first : null;
  }

  Future<void> _syncConfigWithService() async {
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) return;

    final prefs = PreferencesService();
    
    Map<String, String> texts = {};
    
    if (oksigeniaNavigatorKey.currentContext != null) {
      final l10n = AppLocalizations.of(oksigeniaNavigatorKey.currentContext!);
      if (l10n != null) {
        texts = {
          'alertFallDetected': l10n.alertFallDetected,
          'holdToCancel': l10n.holdToCancel,
          'alertSendingIn': l10n.alertSendingIn,
          'statusSent': l10n.statusSent,
          'statusReady': l10n.statusReady,
          'smsHelpMessage': l10n.smsHelpMessage,
          'smsDyingGasp': l10n.smsDyingGasp,
          'pauseTitle': l10n.pauseTitle,
          'resumeNow': l10n.pauseResumeNow,
        };
      }
    } else {
      final sharedPrefs = await SharedPreferences.getInstance();
      String langCode = sharedPrefs.getString('language_code') ?? 'en';
      try {
        final l10n = await AppLocalizations.delegate.load(Locale(langCode));
        texts = {
          'alertFallDetected': l10n.alertFallDetected,
          'holdToCancel': l10n.holdToCancel,
          'alertSendingIn': l10n.alertSendingIn,
          'statusSent': l10n.statusSent,
          'statusReady': l10n.statusReady,
          'smsHelpMessage': l10n.smsHelpMessage,
          'smsDyingGasp': l10n.smsDyingGasp,
          'pauseTitle': l10n.pauseTitle,
          'resumeNow': l10n.pauseResumeNow,
        };
      } catch (_) {}
    }

    service.invoke("setConfig", {
      "recipients": prefs.getContacts(),
      "customMessage": prefs.getSosMessage(),
      "texts": texts
    });
  }

  Future<void> init() async {
    if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) {
      return; 
    }

    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    
    // 🟢 FIX: Limpieza de buffer. Forzamos 1.0G visualmente al inicio.
    _visualGForce = 1.0;
    _ignoreSensors = true;
    // Aumentado a 4 segundos para asegurar purga completa
    Future.delayed(const Duration(seconds: 4), () => _ignoreSensors = false);
    
    await _loadSettings();
    await _checkPermissions(); 
    
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
    }
    
    Future.delayed(const Duration(seconds: 1), () => _syncConfigWithService());

    service.on("onPauseResumed").listen((_) {
      _pausedUntil = null;
      _lastMovementTime = DateTime.now();
      _updateSylviaStatus();
      notifyListeners();
    });

    service.on("onLiveTrackingSent").listen((_) async {
      if (_isLiveTrackingActive) {
        _liveTrackingNextSend = DateTime.now().add(Duration(minutes: _liveTrackingIntervalMinutes));
      }
      notifyListeners();
    });

    service.on("sentinelYellow").listen((_) {
      _sentinelYellow = true;
      _sentinelOrange = false;
      notifyListeners();
    });

    service.on("sentinelOrange").listen((_) {
      _sentinelYellow = true;
      _sentinelOrange = true;
      notifyListeners();
    });

    service.on("sentinelGreen").listen((_) {
      _sentinelYellow = false;
      _sentinelOrange = false;
      notifyListeners();
    });

    service.on("onAlarmTriggered").listen((_) {
      _sentinelYellow = false;
      _sentinelOrange = false;
      _triggerPreAlert(AlertCause.fall, startedByService: true);
    });

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
      try {
        _fullScreenIntentOk = await platform.invokeMethod('canUseFullScreenIntent') ?? true;
      } catch (_) {}
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

  Future<void> requestFullScreenIntentPermission() async {
    try {
      await platform.invokeMethod('requestFullScreenIntentPermission');
      await Future.delayed(const Duration(milliseconds: 500));
      _fullScreenIntentOk = await platform.invokeMethod('canUseFullScreenIntent') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) return;
      
      _startGForceMonitoring(); 
      _checkHealth();
      if (_status == SOSStatus.ready) _startPassiveGPS();
      _syncConfigWithService();
      
    } else if (state == AppLifecycleState.paused) {
      if (!_isInactivityMonitorActive && !_isFallDetectionActive) {
         _accelerometerSubscription?.cancel();
      }
    } 
  }

  Future<void> _loadSettings() async {
    final prefs = PreferencesService();
    _currentInactivityLimit = prefs.getInactivityTime();
    _isLiveTrackingActive = prefs.getLiveTrackingEnabled();
    _liveTrackingIntervalMinutes = prefs.getLiveTrackingIntervalMinutes();
    
    bool hasContact = emergencyContact != null;
    bool savedFallState = prefs.getFallDetectionState();
    
    if (savedFallState && hasContact) {
      _isFallDetectionActive = true; 
    } else {
      _isFallDetectionActive = false;
      if (savedFallState) prefs.saveFallDetectionState(false);
    }
    
    bool savedInactivityState = prefs.getInactivityState();
    bool inactivityToggleSentSetMonitoring = false;
    // Awaited intentionally — toggleInactivityMonitor calls startService(),
    // and the init flow below also checks isRunning() and may call it again.
    // Without the await, both fire concurrently and trigger a second
    // startForegroundService() that Android can't satisfy → FGS timeout.
    if (savedInactivityState && hasContact) {
      if (!_isInactivityMonitorActive) {
        await toggleInactivityMonitor(true);
        inactivityToggleSentSetMonitoring = true;
      }
    } else {
      if (_isInactivityMonitorActive) {
        await toggleInactivityMonitor(false);
        inactivityToggleSentSetMonitoring = true;
      }
      if (savedInactivityState) prefs.saveInactivityState(false);
    }

    // Skip the redundant invoke when toggleInactivityMonitor already sent it.
    // Two startForegroundService calls within ~150ms have triggered
    // ForegroundServiceDidNotStartInTimeException on Pixel 7 (Android 14, FGS
    // type=location). One coalesced invoke avoids the race entirely.
    if (!inactivityToggleSentSetMonitoring) {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
         service.invoke("setMonitoring", {
           "active": _isFallDetectionActive,
           "inactivity_limit": _currentInactivityLimit,
           "inactivity_enabled": _isInactivityMonitorActive,
           "profile": PreferencesService().getActivityProfile().name,
         });
      }
    }

    if (_errorMessage == "NO_CONTACT") {
       if (hasContact || (!_isFallDetectionActive && !_isInactivityMonitorActive)) {
         _setStatus(SOSStatus.ready);
       }
    }

    final rawPrefs = await SharedPreferences.getInstance();

    // Check if inactivity AlarmClock fired during Doze (screen was off, Timer was frozen)
    final int scheduledFor = rawPrefs.getInt('inactivity_alarm_scheduled_for') ?? 0;
    final bool inactivityWasEnabled = rawPrefs.getBool('inactivity_monitor_enabled') ?? false;
    if (scheduledFor > 0 &&
        scheduledFor <= DateTime.now().millisecondsSinceEpoch &&
        inactivityWasEnabled) {
      debugPrint("LOGIC: ⏰ AlarmClock de inactividad disparado durante Doze. Activando zombie.");
      await rawPrefs.setBool('is_alarm_active', true);
      await rawPrefs.setInt('alarm_start_timestamp', scheduledFor);
      await rawPrefs.setInt('inactivity_alarm_scheduled_for', 0);
    }

    bool isZombieAlarming = rawPrefs.getBool('is_alarm_active') ?? false;

    if (isZombieAlarming) {
       debugPrint("LOGIC: 🧟 ¡Detectada alarma zombie!");
       try { await platform.invokeMethod('wakeScreen'); } catch (_) {}

       int startTime = rawPrefs.getInt('alarm_start_timestamp') ?? 0;
       int now = DateTime.now().millisecondsSinceEpoch;
       int elapsedSeconds = ((now - startTime) / 1000).floor();
       int remaining = 30 - elapsedSeconds;

       if (remaining > 0) {
          _status = SOSStatus.preAlert;
          _countdownSeconds = remaining; 
          
          Future.delayed(const Duration(milliseconds: 500), () {
              if (oksigeniaNavigatorKey.currentState != null) {
                oksigeniaNavigatorKey.currentState!.popUntil((route) => route.isFirst);
                oksigeniaNavigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (context) => const AlarmScreen())
                );
              }
          });
          
          _preAlertTimer?.cancel();
          _preAlertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _countdownSeconds--;
            notifyListeners();
            if (_countdownSeconds <= 0) {
              timer.cancel();
              if (_lastTrigger == AlertCause.manual) {
                 sendSOS();
              } else {
                 _onAutoAlertSent();
              }
            }
          });
          notifyListeners();
          return; 
       } else {
          debugPrint("LOGIC: 🧟 Tiempo agotado. Esperando confirmación de Sylvia...");
          await rawPrefs.setBool('is_alarm_active', false);
       }
    }

    bool sentRecently = rawPrefs.getBool('sos_sent_recently') ?? false;
    if (sentRecently) {
       _status = SOSStatus.sent;
       await rawPrefs.setBool('sos_sent_recently', false); 
       Future.delayed(const Duration(milliseconds: 500), () {
          if (oksigeniaNavigatorKey.currentState != null) {
             oksigeniaNavigatorKey.currentState!.popUntil((route) => route.isFirst);
             oksigeniaNavigatorKey.currentState!.push(
                MaterialPageRoute(builder: (context) => const SentScreen())
             );
          }
       });
       notifyListeners();
    }
  }

  void _onAutoAlertSent() async {
    _setStatus(SOSStatus.sent);
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool('sos_sent_recently', true);
    await sharedPrefs.setBool('is_alarm_active', false);
    
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

    if (oksigeniaNavigatorKey.currentState != null) {
       oksigeniaNavigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(builder: (context) => const SentScreen())
       );
    }
  }

  Future<void> refreshConfig() async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    await _loadSettings();
    _updateSylviaStatus();
    _syncConfigWithService();
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
    _isWarmingUp = true;
    _visualGForce = 1.0;
    final DateTime streamStart = DateTime.now();
    int samplesSeen = 0;
    // Z-only bias tracker (matches service-side rationale). Pixel 8 has a stuck z axis
    // (~197 m/s²); X and Y on healthy sensors don't need filtering and removing them
    // avoids transient amplification when the phone reorients quickly (e.g. taking off
    // a backpack after sustained walking).
    double zBias = 0.0;
    const double biasAlpha = 0.998; // ~5s time constant at 50Hz
    Future.delayed(const Duration(seconds: 3), () {
      _isWarmingUp = false;
      notifyListeners();
    });
    double lastG = 1.0;

    try {
      _accelerometerSubscription = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((UserAccelerometerEvent event) {

          if (_ignoreSensors) {
            return;
          }

          _lastSensorPacket = DateTime.now();

          samplesSeen++;
          if (samplesSeen == 1) {
            zBias = event.z;
          } else {
            zBias = biasAlpha * zBias + (1 - biasAlpha) * event.z;
          }
          final double effX = event.x;
          final double effY = event.y;
          final double effZ = event.z - zBias;
          final double userMagnitude = sqrt(effX * effX + effY * effY + effZ * effZ);
          final double instantG = 1.0 + userMagnitude / 9.81;

          final bool sensorWarmup = samplesSeen < 100 ||
              DateTime.now().difference(streamStart).inMilliseconds < 4000;
          if (_isWarmingUp || sensorWarmup) {
            _visualGForce = 1.0;
            notifyListeners();
            return;
          }

          if (instantG > _visualGForce) {
            _visualGForce = instantG;
          } else {
            _visualGForce = (_visualGForce * 0.90) + (instantG * 0.10);
          }

          notifyListeners();

          if (_uiCooldown) return;
          if (_status == SOSStatus.sent) return;

          double delta = (instantG - lastG).abs();
          lastG = instantG;

          if (delta > 0.15 || instantG > 1.15 || instantG < 0.85) {
             _lastMovementTime = DateTime.now();
          }

          if (DateTime.now().difference(_lastCancellationTime).inSeconds < 3) {
             return;
          }

          // Impact detection lives in Sylvia (background_service.dart) so every fall
          // goes through Smart Sentinel observation. UI sensor here only powers the
          // visual gauge and tracks _lastMovementTime for inactivity logic.
        }, onError: (e) => debugPrint("Sensor Error: $e"));
    } catch (e) { debugPrint("Error acelerómetro: $e"); }
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.notification,
      Permission.activityRecognition,
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
      _uiCooldown = true;
      Future.delayed(const Duration(seconds: 2), () => _uiCooldown = false);

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

    final service = FlutterBackgroundService();
    service.invoke("setMonitoring", {
      "active": value,
      "inactivity_limit": _currentInactivityLimit,
      "inactivity_enabled": _isInactivityMonitorActive,
      "profile": PreferencesService().getActivityProfile().name,
    });
    _syncConfigWithService();

    PreferencesService().saveFallDetectionState(value);
    _updateSylviaStatus(); 
    notifyListeners();
  }

  Future<void> toggleInactivityMonitor(bool value) async {
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
    
    service.invoke("setMonitoring", {
      "active": _isFallDetectionActive,
      "inactivity_limit": _currentInactivityLimit,
      "inactivity_enabled": value,
      "profile": PreferencesService().getActivityProfile().name,
    });
    _syncConfigWithService();

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
        if (isMonitoringPaused) return;
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

  void _triggerPreAlert(AlertCause cause, {bool startedByService = false}) async {
    if (_status == SOSStatus.preAlert || _status == SOSStatus.sent) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_start_timestamp');

    debugPrint("SYLVIA: 🚨 ALARMA ACTIVADA");
    _lastTrigger = cause;
    _status = SOSStatus.preAlert;
    _countdownSeconds = 30;
    _updateSylviaStatus();
    notifyListeners();

    _gpsSubscription?.pause();

    if (!startedByService) {
      try {
         final service = FlutterBackgroundService();
         service.invoke("startAlarm");
         Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
      } catch (e) { debugPrint("Error servicio: $e"); }
    }

    _preAlertTimer?.cancel();
    _preAlertTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners(); 
      if (_countdownSeconds <= 0) {
        timer.cancel();
        if (_lastTrigger == AlertCause.manual) {
           sendSOS();
        } else {
           _onAutoAlertSent();
        }
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

      msg += "\nhttps://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      
      for (String number in recipients) {
        await _telephony.sendSms(to: number, message: msg);
      }
    } catch (e) { debugPrint("❌ Fallo Dying Gasp: $e"); }
  }

  void cancelAlert() => cancelSOS();

  void cancelSOS() async {
    debugPrint("LOGIC: 🛑 Cancelado por usuario.");
    try { await platform.invokeMethod('sleepScreen'); } catch (_) {}
    
    _uiCooldown = true;
    Future.delayed(const Duration(seconds: 10), () => _uiCooldown = false);

    _lastCancellationTime = DateTime.now(); 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_alarm_active', false);
    await prefs.remove('alarm_start_timestamp');
    await prefs.setBool('sos_sent_recently', false);

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
      _lastMovementTime = DateTime.now();
    }
    _updateSylviaStatus(); 
    
    if (oksigeniaNavigatorKey.currentState != null) {
      oksigeniaNavigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false
      );
    }
    
    notifyListeners();
  }

  void resetSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sos_sent_recently', false);
    await prefs.setBool('is_alarm_active', false);
    
    _setStatus(SOSStatus.ready);
    _lastMovementTime = DateTime.now();
    
    if (oksigeniaNavigatorKey.currentState != null) {
      oksigeniaNavigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false
      );
    }
    notifyListeners();
  }

  Future<void> stopSystem() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("stopService");
      await Future.delayed(const Duration(milliseconds: 600));
    }

    final prefs = PreferencesService();
    prefs.saveFallDetectionState(false);
    prefs.saveInactivityState(false);
    prefs.setLiveTrackingEnabled(false);

    _isFallDetectionActive = false;
    _isInactivityMonitorActive = false;
    _isLiveTrackingActive = false;
    _liveTrackingNextSend = null;
    _setStatus(SOSStatus.ready);

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
      Position? pos;
      try {
        final LocationSettings locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 5));
        pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null) {
        _setStatus(SOSStatus.locationFixed);
        msgBody += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${pos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${pos.accuracy.toStringAsFixed(0)}m";
      } else {
        msgBody += "\n(GPS Error/Timeout)";
        msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
      }
    } catch (e) {
      msgBody += "\n(GPS Error/Timeout)";
      msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
    }

    int successCount = 0;
    for (String number in recipients) {
      try {
        await _telephony.sendSms(
          to: number, 
          message: msgBody,
          isMultipart: true
        );
        successCount++;
      } catch (e) { debugPrint("Error enviando: $e"); }
    }

    if (successCount > 0) {
      try {
        final service = FlutterBackgroundService();
        service.invoke("stopAlarm");
        Vibration.cancel(); 
      } catch (e) {}

      _setStatus(SOSStatus.sent);
      
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setBool('sos_sent_recently', true);
      await sharedPrefs.setBool('is_alarm_active', false);

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
        updateMsg += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        updateMsg += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        await _telephony.sendSms(to: target, message: updateMsg);
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
    
    super.dispose();
  }

  Future<void> pauseMonitoring(Duration duration) async {
    _pauseFrozenElapsed = DateTime.now().difference(_lastMovementTime).inSeconds;
    _pausedUntil = DateTime.now().add(duration);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("setPaused", {"until": _pausedUntil!.millisecondsSinceEpoch});
    }
    _updateSylviaStatus();
    notifyListeners();
  }

  /// Re-send the current monitoring configuration to Sylvia. Called when the
  /// activity profile changes mid-session so the new parameters take effect
  /// without requiring the user to toggle monitoring off/on.
  Future<void> reapplyMonitoringConfig() async {
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) return;
    service.invoke("setMonitoring", {
      "active": _isFallDetectionActive,
      "inactivity_limit": _currentInactivityLimit,
      "inactivity_enabled": _isInactivityMonitorActive,
      "profile": PreferencesService().getActivityProfile().name,
    });
  }

  Future<void> resumeMonitoring() async {
    _pausedUntil = null;
    _lastMovementTime = DateTime.now();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("setPaused", {"until": 0});
      service.invoke("setMonitoring", {
        "active": _isFallDetectionActive,
        "inactivity_limit": _currentInactivityLimit,
        "inactivity_enabled": _isInactivityMonitorActive,
        "profile": PreferencesService().getActivityProfile().name,
      });
    }
    _updateSylviaStatus();
    notifyListeners();
  }

  Future<void> enableLiveTracking(int intervalMinutes, int shutdownMinutes) async {
    final prefs = PreferencesService();
    _isLiveTrackingActive = true;
    _liveTrackingIntervalMinutes = intervalMinutes;
    _liveTrackingNextSend = DateTime.now().add(Duration(minutes: intervalMinutes));
    await prefs.setLiveTrackingEnabled(true);
    await prefs.setLiveTrackingIntervalMinutes(intervalMinutes);
    await prefs.setLiveTrackingShutdownMinutes(shutdownMinutes);

    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) await service.startService();
    service.invoke("setLiveTracking", {
      "active": true,
      "interval_seconds": intervalMinutes * 60,
      "shutdown_seconds": shutdownMinutes * 60,
    });
    notifyListeners();
  }

  Future<void> disableLiveTracking() async {
    _isLiveTrackingActive = false;
    _liveTrackingNextSend = null;
    await PreferencesService().setLiveTrackingEnabled(false);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("setLiveTracking", {"active": false});
    }
    notifyListeners();
  }

  Future<void> sendLiveCheckin() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("sendLiveCheckin");
    }
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
        String statusIcon = "active"; 

        if (_status == SOSStatus.preAlert) {
          statusIcon = "alarm";
          title = "🚨 SOS";
          content = t.alertFallDetected;
        } else if (isActive && isMonitoringPaused) {
          statusIcon = "paused";
          final mins = pauseRemainingSeconds ~/ 60;
          final secs = (pauseRemainingSeconds % 60).toString().padLeft(2, '0');
          title = "⏸ ${t.pauseTitle}";
          content = "${t.pauseResumeNow} — ${mins}m${secs}s";
        } else if (!isActive) {
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
    }
  }
}