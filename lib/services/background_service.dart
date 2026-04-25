import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const String channelId = 'my_foreground';
const String alarmChannelId = 'oksigenia_alarm';
const int notificationId = 888;
const int alarmNotifId = 890;
const int _liveTrackingAlarmId = 891;
const int _liveTrackingShutdownAlarmId = 892;

// 🟢 CAMBIO: AudioPlayer ahora es dinámico, no estático
AudioPlayer? _audioPlayer;
final Telephony _telephony = Telephony.instance;
final Battery _battery = Battery();

// Variables de Configuración
List<String> _recipients = [];
String _customMessage = "";
Map<String, String> _texts = {
  'alertFallDetected': 'IMPACT DETECTED!',
  'holdToCancel': 'Hold to cancel',
  'alertSendingIn': 'Sending alert in...',
  'statusSent': 'Alert sent successfully.',
  'statusReady': 'Oksigenia System Ready.',
  'smsHelpMessage': 'HELP! SOS!',
  'smsDyingGasp': 'BATTERY CRITICAL. Bye.',
  'pauseTitle': 'Monitoring paused',
  'resumesIn': 'Resumes in',
  'resumeNow': 'Resume now',
};

// Variables Globales
Timer? _zombieTimer;
DateTime _lastStopTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'Oksigenia SOS Service',
    description: 'Running in background monitoring sensors',
    importance: Importance.defaultImportance,
  );

  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    'oksigenia_alarm',
    'Oksigenia SOS Alarm',
    description: 'Emergency lock-screen alarms',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(alarmChannel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'Oksigenia SOS',
      initialNotificationContent: 'System Initializing...',
      autoStart: true, 
      autoStartOnBoot: true, 
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  const MethodChannel platform = MethodChannel('com.oksigenia.sos/sms');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int _zombieCountdown = 30;
  StreamSubscription? _accSub;

  bool _isMonitoringImpact = false;
  bool _isMonitoringInactivity = false;
  bool _isAlarmActive = false;

  DateTime _lastMovementTime = DateTime.now();
  int _inactivityLimitSeconds = 3600;
  Timer? _inactivityCheckTimer;

  // AlarmClock anti-Doze
  const int _inactivityAlarmNotifId = 889;
  DateTime _lastAlarmReschedule = DateTime.fromMillisecondsSinceEpoch(0);

  // Timed pause
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // Live Tracking
  bool _isLiveTrackingActive = false;
  int _liveTrackingIntervalSeconds = 1800;
  DateTime _liveTrackingNextSend = DateTime.fromMillisecondsSinceEpoch(0);

  bool _sensorCooldown = false;
  const double _yellowThreshold = 3.5;
  double _lastG = 1.0;
  final List<double> _gBuffer = [];
  bool _sentinelYellow = false;
  int _yellowCountdown = 60;
  Timer? _yellowTimer;
  Timer? _shieldTimer;

  final DateTime serviceStartupTime = DateTime.now();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_oksigenia');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (details) async {
      if (details.actionId == 'resume_monitoring') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('pause_resume_requested', DateTime.now().millisecondsSinceEpoch);
      }
    },
    onDidReceiveBackgroundNotificationResponse: _handleNotificationAction,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'oksigenia_alarm',
        'Oksigenia SOS Alarm',
        description: 'Emergency lock-screen alarms',
        importance: Importance.max,
      ));

  // ---------------------------------------------------------------------------
  // 1. GESTIÓN DE AUDIO ROBUSTA (Crear y Destruir)
  // ---------------------------------------------------------------------------
  
  Future<void> _reproducirSonidoAlarma() async {
    try {
      // Matar anterior si existe
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      // Crear nuevo fresco
      _audioPlayer = AudioPlayer();
      
      await _audioPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
      ));
      
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      print("SYLVIA AUDIO ERROR: $e");
    }
  }

  Future<void> _detenerSonido() async {
    final player = _audioPlayer;
    _audioPlayer = null;
    try { await player?.stop(); } catch (_) {}
    try { await player?.dispose(); } catch (_) {}
  }

  Future<void> _reproducirConfirmacion() async {
    final old = _audioPlayer;
    _audioPlayer = null;
    try { await old?.stop(); } catch (_) {}
    try { await old?.dispose(); } catch (_) {}
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(AssetSource('sounds/send.mp3'));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 2. FUNCIONES AUXILIARES
  // ---------------------------------------------------------------------------

  void _activarEscudo({int segundos = 3}) {
    _sensorCooldown = true;
    _shieldTimer?.cancel();
    _shieldTimer = Timer(Duration(seconds: segundos), () => _sensorCooldown = false);
  }

  Future<void> _scheduleInactivityAlarmClock() async {
    if (!_isMonitoringInactivity) return;
    try {
      tz.initializeTimeZones();
      final scheduledDate = tz.TZDateTime.now(tz.UTC).add(Duration(seconds: _inactivityLimitSeconds));
      await flutterLocalNotificationsPlugin.cancel(id: _inactivityAlarmNotifId);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: _inactivityAlarmNotifId,
        title: "🚨 OKSIGENIA SOS",
        body: _texts['holdToCancel'] ?? 'Hold to cancel',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId, 'Oksigenia SOS Alarm',
            icon: 'ic_stat_oksigenia',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            color: Color(0xFFFF0000),
            playSound: false,
            enableVibration: false,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('inactivity_alarm_scheduled_for', scheduledDate.millisecondsSinceEpoch);
      _lastAlarmReschedule = DateTime.now();
      print("SYLVIA: ⏰ AlarmClock programado en ${_inactivityLimitSeconds}s");
    } catch (e) {
      print("SYLVIA: Error al programar AlarmClock: $e");
    }
  }

  Future<void> _cancelInactivityAlarmClock() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: _inactivityAlarmNotifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('inactivity_alarm_scheduled_for', 0);
    } catch (_) {}
  }

  Future<void> _scheduleLiveTrackingAlarm() async {
    try {
      tz.initializeTimeZones();
      final scheduledDate = tz.TZDateTime.now(tz.UTC).add(Duration(seconds: _liveTrackingIntervalSeconds));
      _liveTrackingNextSend = scheduledDate;
      await flutterLocalNotificationsPlugin.cancel(id: _liveTrackingAlarmId);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: _liveTrackingAlarmId,
        title: "📍 Live Tracking",
        body: "Sending position update...",
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId, 'Oksigenia SOS Alarm',
            icon: 'ic_stat_oksigenia',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('live_tracking_next_send', scheduledDate.millisecondsSinceEpoch);
      print("SYLVIA: 📍 Live Tracking alarm scheduled in ${_liveTrackingIntervalSeconds}s");
    } catch (e) {
      print("SYLVIA: Live Tracking alarm error: $e");
    }
  }

  Future<void> _cancelLiveTrackingAlarm() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: _liveTrackingAlarmId);
      await flutterLocalNotificationsPlugin.cancel(id: _liveTrackingShutdownAlarmId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('live_tracking_next_send', 0);
    } catch (_) {}
  }

  Future<void> _scheduleShutdownReminder(int afterSeconds) async {
    try {
      tz.initializeTimeZones();
      final scheduledDate = tz.TZDateTime.now(tz.UTC).add(Duration(seconds: afterSeconds));
      await flutterLocalNotificationsPlugin.cancel(id: _liveTrackingShutdownAlarmId);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: _liveTrackingShutdownAlarmId,
        title: "⏰ Oksigenia SOS",
        body: "Live Tracking shutdown reminder. Open app to continue.",
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId, 'Oksigenia SOS Alarm',
            icon: 'ic_stat_oksigenia',
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      print("SYLVIA: ⏰ Shutdown reminder scheduled in ${afterSeconds}s");
    } catch (e) {
      print("SYLVIA: Shutdown reminder error: $e");
    }
  }

  Future<void> _sendLiveTrackingSMS({bool isCheckin = false}) async {
    if (_recipients.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _recipients = prefs.getStringList('contacts') ?? [];
      if (_recipients.isEmpty) return;
    }

    String target = _recipients.first;
    int batteryLevel = 0;
    try { batteryLevel = await _battery.batteryLevel; } catch (_) {}

    String header = isCheckin
        ? "✅ I'M OK — Oksigenia SOS"
        : "📍 LIVE TRACKING — Oksigenia SOS";

    String msgBody = header;
    if (_customMessage.isNotEmpty && !isCheckin) {
      msgBody += "\n$_customMessage";
    }

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null) {
        msgBody += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        if (!isCheckin) {
          msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        }
        msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${pos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${pos.accuracy.toStringAsFixed(0)}m";
      } else {
        msgBody += "\n(No GPS)\n\n🔋Bat: $batteryLevel%";
      }
    } catch (_) {
      msgBody += "\n(GPS Error)\n\n🔋Bat: $batteryLevel%";
    }

    try {
      await _telephony.sendSms(to: target, message: msgBody, isMultipart: true);
      print("SYLVIA: 📍 Live Tracking SMS enviado a $target");
    } catch (e) {
      print("SYLVIA: ❌ Live Tracking SMS error: $e");
    }

    service.invoke("onLiveTrackingSent");

    if (_isLiveTrackingActive && !isCheckin) {
      await _scheduleLiveTrackingAlarm();
    }
  }

  void _updatePausedNotification() {
    final remaining = _pausedUntil.difference(DateTime.now());
    final totalMin = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    final timeStr = totalMin > 0 ? "${totalMin}m ${secs.toString().padLeft(2, '0')}s" : "${remaining.inSeconds}s";
    final pauseLabel = _texts['pauseTitle'] ?? 'Monitoring paused';
    final resumesInLabel = _texts['resumesIn'] ?? 'Resumes in';
    final resumeNowLabel = _texts['resumeNow'] ?? 'Resume now';
    flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: "⏸ Oksigenia SOS — $pauseLabel",
      body: "$resumesInLabel $timeStr",
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, 'Oksigenia SOS',
          icon: 'ic_stat_oksigenia',
          ongoing: true,
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          actions: [
            AndroidNotificationAction(
              'resume_monitoring',
              resumeNowLabel,
              showsUserInterface: false,
              cancelNotification: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarSMSZombie() async {
    print("SYLVIA SERVICE: 🧟 TIEMPO AGOTADO. Ejecutando protocolo...");

    if (_recipients.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _recipients = prefs.getStringList('contacts') ?? [];
      if (_recipients.isEmpty) {
         print("SYLVIA FATAL: No hay contactos configurados.");
         return;
      }
    }

    String msgBody = "🆘 SOS OKSIGENIA";
    if (_customMessage.isNotEmpty) {
      msgBody += "\n$_customMessage";
    } else {
      msgBody += "\n${_texts['smsHelpMessage']}";
    }

    int batteryLevel = 0;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null) {
        msgBody += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
        msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
        msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${pos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${pos.accuracy.toStringAsFixed(0)}m";
      } else {
        msgBody += "\n(GPS Error/Timeout)";
        msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
      }
    } catch (e) {
      print("SYLVIA ERROR: GPS Falló ($e). Enviando sin loc.");
      msgBody += "\n(GPS Error/Timeout)";
      msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
    }

    for (String number in _recipients) {
      try {
        await _telephony.sendSms(
          to: number,
          message: msgBody,
          isMultipart: true,
        );
        print("SYLVIA: SMS enviado a $number vía Telephony");
      } catch (e) {
        print("SYLVIA ERROR: Fallo al enviar a $number: $e");
      }
    }
    
    await _reproducirConfirmacion();
  }

  Future<void> _lanzarAlarma() async {
    print("SYLVIA SERVICE: 🚨 EJECUTANDO PROTOCOLO DE ALARMA");
    _isAlarmActive = true;
    await _cancelInactivityAlarmClock();
    // Pause live tracking during SOS — watchdog checks _isAlarmActive
    if (_isLiveTrackingActive) {
      print("SYLVIA: 📍 Live Tracking paused during SOS");
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_alarm_active', true);
      await prefs.setInt('alarm_start_timestamp', DateTime.now().millisecondsSinceEpoch);

      // fullScreenIntent: Android launches the Activity over the lock screen automatically.
      // This is the only reliable mechanism from the service isolate — MethodChannel calls
      // to 'com.oksigenia.sos/sms' fail silently here because that channel is registered
      // on the UI engine, not the background engine.
      await flutterLocalNotificationsPlugin.show(
        id: alarmNotifId,
        title: "🚨 ${_texts['alertFallDetected']}",
        body: _texts['holdToCancel'],
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId, 'Oksigenia SOS Alarm',
            icon: 'ic_stat_oksigenia',
            ongoing: true,
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            color: Color(0xFFFF0000),
            playSound: false,
            enableVibration: false,
          ),
        ),
      );

      if (service is AndroidServiceInstance) service.setAsForegroundService();
      service.invoke("onAlarmTriggered");

      // 🟢 USAR EL NUEVO MÉTODO DE AUDIO ROBUSTO
      await _reproducirSonidoAlarma();

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
      }

      _zombieCountdown = 30;
      _zombieTimer?.cancel();
      _zombieTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!_isAlarmActive) {
           print("SYLVIA SERVICE: 🛑 Alarma cancelada detectada dentro del timer. Abortando.");
           timer.cancel();
           await _detenerSonido();
           Vibration.cancel();
           return;
        }

        _zombieCountdown--;
        
        flutterLocalNotificationsPlugin.show(
          id: alarmNotifId,
          title: "${_texts['alertSendingIn']} $_zombieCountdown s",
          body: _texts['holdToCancel'],
          notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                  alarmChannelId, 'Oksigenia SOS Alarm',
                  icon: 'ic_stat_oksigenia',
                  ongoing: true,
                  importance: Importance.max,
                  priority: Priority.max,
                  color: Color(0xFFFF0000),
                  playSound: false,
                  enableVibration: false,
                  onlyAlertOnce: true)),
        );

        if (_zombieCountdown <= 0) {
          timer.cancel();
          await _detenerSonido();
          Vibration.cancel();
          
          await _enviarSMSZombie();

          await prefs.setBool('sos_sent_recently', true);

          _lastMovementTime = DateTime.now().add(const Duration(seconds: 60));

          await flutterLocalNotificationsPlugin.cancel(id: alarmNotifId);
          flutterLocalNotificationsPlugin.show(
            id: notificationId,
            title: _texts['statusSent'],
            body: _texts['statusReady'],
            notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                    channelId, 'Oksigenia SOS',
                    icon: 'ic_stat_oksigenia',
                    importance: Importance.high)),
          );
          await prefs.setBool('is_alarm_active', false);
          _isAlarmActive = false;
          
          try { await platform.invokeMethod('sleepScreen'); } catch (_) {}
        }
      });
    } catch (e) {
      print("Error lanzando alarma: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Smart Sentinel — ordered after _lanzarAlarma (Dart requires declaration before use)
  // ---------------------------------------------------------------------------

  void _returnToGreen() {
    _sentinelYellow = false;
    _yellowTimer?.cancel();
    _yellowCountdown = 60;
    _gBuffer.clear();
  }

  bool _isRhythmicMovement() {
    if (_gBuffer.length < 30) return false;
    final recent = _gBuffer.length > 60
        ? _gBuffer.sublist(_gBuffer.length - 60)
        : List<double>.from(_gBuffer);
    int crossings = 0;
    bool aboveOne = recent[0] > 1.0;
    for (int i = 1; i < recent.length; i++) {
      final bool curr = recent[i] > 1.0;
      if (curr != aboveOne) {
        crossings++;
        aboveOne = curr;
      }
    }
    // Walking/running generates ~2 steps/sec → ≥3 crossings in ~1 second of data
    return crossings >= 3;
  }

  void _enterYellowState() {
    if (_sentinelYellow || _isAlarmActive) return;
    print("SYLVIA SERVICE: 🟡 Impacto detectado. Análisis Smart Sentinel ($_yellowCountdown s)...");
    _sentinelYellow = true;
    _yellowCountdown = 60;
    _yellowTimer?.cancel();
    _yellowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _yellowCountdown -= 2;
      if (_isRhythmicMovement()) {
        print("SYLVIA SERVICE: ✅ Movimiento rítmico. Falso positivo.");
        _returnToGreen();
        timer.cancel();
        return;
      }
      if (_yellowCountdown <= 0) {
        timer.cancel();
        _returnToGreen();
        if (!_isAlarmActive) {
          print("SYLVIA SERVICE: 🔴 Sin movimiento tras 60s. ACTIVANDO ALARMA.");
          _isAlarmActive = true;
          _lanzarAlarma();
        }
      }
    });
  }

  void _startSensorListener() {
    if (_accSub != null) return;
    print("SYLVIA SERVICE: Iniciando escucha de sensores...");

    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((event) {
      
      // 🟢 FIX: Ignorar los primeros 3 segundos de vida del servicio
      if (DateTime.now().difference(serviceStartupTime).inSeconds < 3) {
        return;
      }

      if (DateTime.now().difference(_lastStopTimestamp).inSeconds < 10) {
        return;
      }

      if (_isAlarmActive || _sensorCooldown) return;

      double rawMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      double instantG = rawMagnitude / 9.81;

      final bool isPaused = _pausedUntil.isAfter(DateTime.now());

      if (_isMonitoringImpact && !isPaused) {
        _gBuffer.add(instantG);
        if (_gBuffer.length > 150) _gBuffer.removeAt(0);

        if (instantG > _yellowThreshold && !_sentinelYellow) {
          print("SYLVIA BACKGROUND: ⚡ Impacto ${instantG.toStringAsFixed(1)}G → Smart Sentinel");
          _activarEscudo(segundos: 3);
          _enterYellowState();
        }
      }

      if (_isMonitoringInactivity) {
        double delta = (instantG - _lastG).abs();
        if (delta > 0.15 || instantG > 1.15 || instantG < 0.85) {
          _lastMovementTime = DateTime.now(); // always update, even while paused
          if (!isPaused && DateTime.now().difference(_lastAlarmReschedule).inSeconds > 60) {
            _scheduleInactivityAlarmClock();
          }
        }
        _lastG = instantG;
      }
    });
  }

  void _startInactivityChecker() {
    _inactivityCheckTimer?.cancel();
    _inactivityCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final bool isPaused = _pausedUntil.isAfter(DateTime.now());

      // Auto-resume when timed pause expires
      if (_pausedUntil.millisecondsSinceEpoch > 0 && !isPaused) {
        print("SYLVIA: ▶ Pausa temporizada finalizada. Reanudando.");
        _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
        _lastMovementTime = DateTime.now();
        if (_isMonitoringInactivity) _scheduleInactivityAlarmClock();
        service.invoke("onPauseResumed");
      }

      // Check "Resume now" action tapped on notification
      try {
        final prefs = await SharedPreferences.getInstance();
        final int resumeReq = prefs.getInt('pause_resume_requested') ?? 0;
        if (resumeReq > 0) {
          await prefs.setInt('pause_resume_requested', 0);
          _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
          _lastMovementTime = DateTime.now();
          if (_isMonitoringInactivity) _scheduleInactivityAlarmClock();
          service.invoke("onPauseResumed");
        }
      } catch (_) {}

      // Update pause countdown in notification
      if (_pausedUntil.isAfter(DateTime.now())) {
        _updatePausedNotification();
        return;
      }

      // Live Tracking watchdog: fire when AlarmClock-scheduled time is reached
      if (_isLiveTrackingActive && !_isAlarmActive) {
        final int nextSendMs = _liveTrackingNextSend.millisecondsSinceEpoch;
        if (nextSendMs > 0 && nextSendMs <= DateTime.now().millisecondsSinceEpoch) {
          _liveTrackingNextSend = DateTime.fromMillisecondsSinceEpoch(0);
          _sendLiveTrackingSMS();
        }
      }

      if (DateTime.now().difference(_lastStopTimestamp).inSeconds < 10) return;
      if (!_isMonitoringInactivity || _isAlarmActive) return;

      final secondsInactive = DateTime.now().difference(_lastMovementTime).inSeconds;
      if (secondsInactive > _inactivityLimitSeconds) {
        print("SYLVIA BACKGROUND: 💤 INACTIVIDAD DETECTADA ($secondsInactive s)");
        _isAlarmActive = true;
        _lanzarAlarma();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 3. CARGA DE CONFIGURACIÓN
  // ---------------------------------------------------------------------------

  Future<void> _loadConfigFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recipients = prefs.getStringList('contacts') ?? [];
      _customMessage = prefs.getString('sos_message') ?? "";
      
      bool savedFall = prefs.getBool('fall_detection_enabled') ?? false;
      bool savedInactivity = prefs.getBool('inactivity_monitor_enabled') ?? false;
      _inactivityLimitSeconds = prefs.getInt('inactivity_time') ?? 3600;

      _isLiveTrackingActive = prefs.getBool('live_tracking_enabled') ?? false;
      _liveTrackingIntervalSeconds = (prefs.getInt('live_tracking_interval_minutes') ?? 30) * 60;
      if (_isLiveTrackingActive) {
        final int nextMs = prefs.getInt('live_tracking_next_send') ?? 0;
        _liveTrackingNextSend = DateTime.fromMillisecondsSinceEpoch(nextMs);
        if (nextMs == 0 || nextMs <= DateTime.now().millisecondsSinceEpoch) {
          await _scheduleLiveTrackingAlarm();
        }
        _startInactivityChecker();
        print("SYLVIA BOOT: 📍 Live Tracking restaurado.");
      }

      print("SYLVIA BOOT: Contactos: ${_recipients.length}, Fall: $savedFall, Inactivity: $savedInactivity, LiveTracking: $_isLiveTrackingActive");

      flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: 'Oksigenia SOS',
          body: 'System Ready',
          notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                  channelId, 'Oksigenia SOS - Active Monitor',
                  icon: 'ic_stat_oksigenia',
                  ongoing: true,
                  importance: Importance.low,
                  priority: Priority.low,
                  onlyAlertOnce: true,
                  playSound: false,
                  enableVibration: false))
      );

      if (savedFall || savedInactivity) {
        _isMonitoringImpact = savedFall;
        _isMonitoringInactivity = savedInactivity;
        _startSensorListener();
        if (_isMonitoringInactivity) {
          _startInactivityChecker();
          _scheduleInactivityAlarmClock();
        }
      }
    } catch (e) {
      print("SYLVIA BOOT ERROR: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 4. LISTENERS DEL SERVICIO
  // ---------------------------------------------------------------------------

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());

    service.on('stopService').listen((event) async {
      print("SYLVIA: 💀 Recibida orden de apagado.");
      _accSub?.cancel();
      _inactivityCheckTimer?.cancel();
      _zombieTimer?.cancel();
      _yellowTimer?.cancel();
      _shieldTimer?.cancel();
      await _cancelInactivityAlarmClock();
      await _cancelLiveTrackingAlarm();
      try { await _detenerSonido(); } catch (_) {}
      try { await flutterLocalNotificationsPlugin.cancelAll(); } catch (_) {}
      if (service is AndroidServiceInstance) {
        try { await service.setAsBackgroundService(); } catch (_) {}
      }
      service.stopSelf();
    });

    service.on('setConfig').listen((event) {
      if (event == null) return;
      print("SYLVIA SERVICE: Recibiendo configuración...");
      
      if (event.containsKey('recipients')) {
        _recipients = List<String>.from(event['recipients']);
      }
      if (event.containsKey('customMessage')) {
        _customMessage = event['customMessage'] as String;
      }
      if (event.containsKey('texts')) {
        final Map<dynamic, dynamic> rawTexts = event['texts'];
        rawTexts.forEach((key, value) {
          _texts[key.toString()] = value.toString();
        });
      }
    });

    service.on('setMonitoring').listen((event) async {
      final prefs = await SharedPreferences.getInstance();
      _isMonitoringImpact = event?['active'] ?? false;
      
      if (event != null && event.containsKey('inactivity_limit')) {
         _inactivityLimitSeconds = event['inactivity_limit'];
      } else {
         _inactivityLimitSeconds = prefs.getInt('inactivity_time') ?? 3600;
      }
      
      if (event != null && event.containsKey('inactivity_enabled')) {
         _isMonitoringInactivity = event['inactivity_enabled'];
      } else {
         _isMonitoringInactivity = prefs.getBool('inactivity_monitor_enabled') ?? false;
      }

      print("SYLVIA SERVICE: Monitor - Impact: $_isMonitoringImpact, Inactivity: $_isMonitoringInactivity (Limit: $_inactivityLimitSeconds s)");

      if (_isMonitoringImpact || _isMonitoringInactivity) {
        _activarEscudo(segundos: 2);
        _lastMovementTime = DateTime.now();
        _startSensorListener();
        if (_isMonitoringInactivity) {
          _startInactivityChecker();
          _scheduleInactivityAlarmClock();
        } else {
          if (!_isLiveTrackingActive) _inactivityCheckTimer?.cancel();
          _cancelInactivityAlarmClock();
        }
      } else {
        _accSub?.cancel();
        _accSub = null;
        if (!_isLiveTrackingActive) _inactivityCheckTimer?.cancel();
        _cancelInactivityAlarmClock();
      }
    });

    service.on('setPaused').listen((event) async {
      final int until = event?['until'] ?? 0;
      _pausedUntil = DateTime.fromMillisecondsSinceEpoch(until);
      if (until > 0) {
        await _cancelInactivityAlarmClock();
        _updatePausedNotification();
        print("SYLVIA: ⏸ Monitorización pausada por ${_pausedUntil.difference(DateTime.now()).inMinutes} min");
      } else {
        print("SYLVIA: ▶ Pausa cancelada desde UI");
      }
    });

    service.on('startAlarm').listen((event) => _lanzarAlarma());

    service.on('stopAlarm').listen((event) async {
      print("SYLVIA SERVICE: 🛑 Recibida orden de STOP ALARM");

      _lastStopTimestamp = DateTime.now();

      _isAlarmActive = false;
      _returnToGreen();
      _activarEscudo(segundos: 4);
      _zombieTimer?.cancel();
      await _cancelInactivityAlarmClock();
      
      _lastMovementTime = DateTime.now().add(const Duration(seconds: 15));

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_alarm_active', false);
        await _detenerSonido();
        Vibration.cancel();
        await flutterLocalNotificationsPlugin.cancel(id: alarmNotifId);
        if (_isMonitoringInactivity) _scheduleInactivityAlarmClock();
        if (_isLiveTrackingActive) await _scheduleLiveTrackingAlarm();

        flutterLocalNotificationsPlugin.show(
            id: notificationId,
            title: "Oksigenia SOS",
            body: _texts['statusReady'],
            notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                    channelId, 'Oksigenia SOS - Active Monitor',
                    icon: 'ic_stat_oksigenia',
                    ongoing: true,
                    importance: Importance.low,
                    priority: Priority.low,
                    onlyAlertOnce: true,
                    playSound: false,
                    enableVibration: false)));
      } catch (e) {
        print("Error stop: $e");
      }
    });

    service.on('setLiveTracking').listen((event) async {
      final bool active = event?['active'] ?? false;
      final int intervalSec = event?['interval_seconds'] ?? 1800;
      final int shutdownSec = event?['shutdown_seconds'] ?? 0;
      _isLiveTrackingActive = active;
      _liveTrackingIntervalSeconds = intervalSec;
      if (active) {
        await _scheduleLiveTrackingAlarm();
        if (shutdownSec > 0) await _scheduleShutdownReminder(shutdownSec);
        _startInactivityChecker(); // ensures the 5s watchdog is running
        print("SYLVIA: 📍 Live Tracking activado. Intervalo: ${intervalSec}s");
      } else {
        await _cancelLiveTrackingAlarm();
        print("SYLVIA: 📍 Live Tracking desactivado.");
      }
    });

    service.on('sendLiveCheckin').listen((event) async {
      await _sendLiveTrackingSMS(isCheckin: true);
    });

    service.on('updateNotification').listen((event) async {
      if (event == null) return;
      String status = event['status'] ?? 'active';
      String title = event['title'] ?? 'Oksigenia SOS';
      String content = event['content'] ?? 'Active Monitor';
      const String iconName = 'ic_stat_oksigenia';

      try {
        await flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: title,
          body: content,
          notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                  channelId, 'Oksigenia SOS - Active Monitor',
                  icon: iconName,
                  ongoing: true,
                  importance: Importance.high,
                  priority: Priority.high,
                  onlyAlertOnce: true,
                  playSound: false,
                  enableVibration: false)),
        );
      } catch (e) {}
    });
  }
  
  await _loadConfigFromDisk();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void _handleNotificationAction(NotificationResponse details) async {
  if (details.actionId == 'resume_monitoring') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pause_resume_requested', DateTime.now().millisecondsSinceEpoch);
  }
}