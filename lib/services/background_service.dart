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
import 'package:another_telephony/telephony.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../logic/activity_profile.dart';
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

// File logger for Smart Sentinel events. Persists to app's internal documents
// directory so we can pull it later via:
//   adb shell run-as com.oksigenia.oksigenia_sos cat app_flutter/sentinel.log
File? _sentinelLogFile;

void _logSentinel(String line) {
  print(line);
  _sentinelLogAppend(line);
}

Future<void> _sentinelLogAppend(String line) async {
  try {
    if (_sentinelLogFile == null) {
      final dir = await getApplicationDocumentsDirectory();
      _sentinelLogFile = File('${dir.path}/sentinel.log');
    }
    final ts = DateTime.now().toIso8601String();
    await _sentinelLogFile!
        .writeAsString('$ts $line\n', mode: FileMode.append, flush: true);
  } catch (e) {
    print("SENTINEL LOG err: $e");
  }
}

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
  'smsBeaconHeader': '📍 OKSIGENIA UPDATE — moved',
};

// Smart Beacon: post-SOS position-update SMS protocol.
// Activates when an SOS SMS is sent (auto via _enviarSMSZombie or manual via
// UI sendSOS). Real outdoor rescues take 2–4 hours to arrive; the victim
// may wander, flee, or be carried during that time. If they move >300 m
// from the last reference point, send an update SMS with the new position
// so rescuers always have fresh coordinates. Throttled to one SMS every
// 5 minutes; capped at 20 updates over a 4-hour window. Stops automatically
// after the window or when the user taps "Restart system" on SentScreen.
const double _beaconDistanceM = 300.0;
const int _beaconMinIntervalSeconds = 300;
const int _beaconMaxUpdates = 20;
const int _beaconWindowSeconds = 14400;

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

  // First log line of every service-isolate spawn. If we see this between an
  // impact and an alarm, Android killed and respawned the service mid-yellow.
  _logSentinel("SYLVIA SERVICE: 🚀 onStart entered (isolate spawn)");

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
  // Smart Sentinel runtime parameters (mutable — driven by activity profile).
  // Defaults match the Trekking baseline; setMonitoring overrides on demand.
  double _yellowThreshold = 6.0;
  double _orangeThreshold = 12.0;
  int _settlingSeconds = 5;
  int _observationSeconds = 60;
  double _cvUpperBound = 1.30;
  bool _impactDetectionEnabled = true;
  double _lastG = 1.0;
  final List<double> _gBuffer = [];
  // Effective sample rate of the userAccelerometer stream. Android negotiates
  // SensorInterval.gameInterval (~50Hz target) but actually delivers anywhere
  // from 50–200Hz. Updated once per second from inside the listener.
  double _measuredHz = 50.0;
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

  Future<void> _activateBeacon(Position originPos) async {
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await p.setBool('beacon_active', true);
      await p.setDouble('beacon_origin_lat', originPos.latitude);
      await p.setDouble('beacon_origin_lon', originPos.longitude);
      await p.setInt('beacon_origin_ts', now);
      await p.setDouble('beacon_last_lat', originPos.latitude);
      await p.setDouble('beacon_last_lon', originPos.longitude);
      await p.setInt('beacon_last_ts', now);
      await p.setInt('beacon_count', 0);
      _logSentinel("SYLVIA SERVICE: 📍 Beacon activated at ${originPos.latitude.toStringAsFixed(5)},${originPos.longitude.toStringAsFixed(5)}");
    } catch (e) {
      print("SYLVIA: Beacon activate error: $e");
    }
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

    Position? sosPos;
    try {
      try {
        sosPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)));
      } catch (_) {
        sosPos = await Geolocator.getLastKnownPosition();
      }
      if (sosPos != null) {
        msgBody += "\nMaps: https://maps.google.com/?q=${sosPos.latitude},${sosPos.longitude}";
        msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${sosPos.latitude}&mlon=${sosPos.longitude}";
        msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${sosPos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${sosPos.accuracy.toStringAsFixed(0)}m";
      } else {
        msgBody += "\n(GPS Error/Timeout)";
        msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
      }
    } catch (e) {
      print("SYLVIA ERROR: GPS Falló ($e). Enviando sin loc.");
      msgBody += "\n(GPS Error/Timeout)";
      msgBody += "\n\n🔋Bat: $batteryLevel% (No Loc)";
    }

    int sentCount = 0;
    for (String number in _recipients) {
      try {
        await _telephony.sendSms(
          to: number,
          message: msgBody,
          isMultipart: true,
        );
        sentCount++;
        print("SYLVIA: SMS enviado a $number vía Telephony");
      } catch (e) {
        print("SYLVIA ERROR: Fallo al enviar a $number: $e");
      }
    }

    if (sentCount > 0 && sosPos != null) {
      await _activateBeacon(sosPos);
    }

    await _reproducirConfirmacion();
  }

  Future<void> _beaconTick() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool('beacon_active') ?? false)) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final originTs = p.getInt('beacon_origin_ts') ?? 0;
      final count = p.getInt('beacon_count') ?? 0;

      if (now - originTs > _beaconWindowSeconds * 1000 || count >= _beaconMaxUpdates) {
        await p.setBool('beacon_active', false);
        _logSentinel("SYLVIA SERVICE: 📍 Beacon stopped (window/count reached)");
        return;
      }

      final lastTs = p.getInt('beacon_last_ts') ?? originTs;
      if (now - lastTs < _beaconMinIntervalSeconds * 1000) return;

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;

      final lastLat = p.getDouble('beacon_last_lat') ?? 0;
      final lastLon = p.getDouble('beacon_last_lon') ?? 0;
      final delta = Geolocator.distanceBetween(lastLat, lastLon, pos.latitude, pos.longitude);
      if (delta < _beaconDistanceM) return;

      final originLat = p.getDouble('beacon_origin_lat') ?? 0;
      final originLon = p.getDouble('beacon_origin_lon') ?? 0;
      final totalDist = Geolocator.distanceBetween(originLat, originLon, pos.latitude, pos.longitude);

      final header = _texts['smsBeaconHeader'] ?? '📍 OKSIGENIA UPDATE — moved';
      String msg = "$header ${totalDist.toStringAsFixed(0)}m";
      msg += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      msg += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";

      if (_recipients.isEmpty) {
        _recipients = p.getStringList('contacts') ?? [];
      }
      for (final number in _recipients) {
        try {
          await _telephony.sendSms(to: number, message: msg, isMultipart: true);
        } catch (e) {
          print("SYLVIA: Beacon SMS error: $e");
        }
      }

      await p.setDouble('beacon_last_lat', pos.latitude);
      await p.setDouble('beacon_last_lon', pos.longitude);
      await p.setInt('beacon_last_ts', now);
      await p.setInt('beacon_count', count + 1);
      _logSentinel("SYLVIA SERVICE: 📍 Beacon update #${count + 1} sent (delta ${delta.toStringAsFixed(0)}m, total ${totalDist.toStringAsFixed(0)}m)");
    } catch (e) {
      print("SYLVIA: Beacon tick error: $e");
    }
  }

  Future<void> _writeWidgetState(String state) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('widget_sentinel_state', state);
    } catch (_) {}
  }

  Future<void> _lanzarAlarma() async {
    _logSentinel("SYLVIA SERVICE: 🚨 EJECUTANDO PROTOCOLO DE ALARMA");
    _isAlarmActive = true;
    _writeWidgetState('red');
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
    final bool wasYellow = _sentinelYellow;
    _sentinelYellow = false;
    _yellowTimer?.cancel();
    _yellowCountdown = _observationSeconds;
    _gBuffer.clear();
    _writeWidgetState('green');
    if (wasYellow) service.invoke("sentinelGreen");
  }

  // Cadence-CV "is the user alive and walking" check.
  // Operates on horizontal-G buffer (effX² + effY², Z removed). Resting value
  // ~1.0; walking peaks oscillate above. Z is excluded because the Pixel 8
  // bias filter distorts vertical signal during gait — see _startSensorListener.
  // 2-second analysis window for stable cadence stats:
  //   - >= 4 crossings of 1.12 (above hand-tremor noise; real walking peaks ~1.3-1.5G)
  //   - frequency >= 1.0 Hz (slow walking with heavy load is ~1-1.3Hz; pendulum still <1Hz)
  //   - CV of inter-crossing intervals in [0.05, 1.30]
  //       <0.05 = too regular = mechanical/pendulum
  //       >1.30 = chaotic/random (pure vibration, vehicle on rough road)
  //   Empirical CV from real-life logs (Pixel 7+8, phone in back pocket, walking
  //   + stairs): median ~1.1, range 0.81–1.71. Original 0.85 cap was tuned for
  //   trunk-mounted wearables (Bourke 2007). Smartphones in pockets see fabric
  //   damping + secondary microimpacts that legitimately raise CV.
  // Window length is fixed at ~2s of *real* samples — uses _measuredHz updated
  // by the sensor listener so timing math doesn't depend on Android delivering
  // exactly 50Hz on every device.
  bool _isRhythmicMovement() {
    final int targetWindowSamples = (_measuredHz * 2).round().clamp(50, 400);
    if (_gBuffer.length < targetWindowSamples) return false;
    final recent = _gBuffer.length > targetWindowSamples
        ? _gBuffer.sublist(_gBuffer.length - targetWindowSamples)
        : List<double>.from(_gBuffer);

    const double rhythmThreshold = 1.12;
    final List<int> crossingIdx = [];
    bool above = recent[0] > rhythmThreshold;
    for (int i = 1; i < recent.length; i++) {
      final bool curr = recent[i] > rhythmThreshold;
      if (curr != above) {
        crossingIdx.add(i);
        above = curr;
      }
    }

    final int crossings = crossingIdx.length;
    if (crossings < 4) {
      _logSentinel("SYLVIA RHYTHM: crossings=$crossings (< 4) → NO");
      return false;
    }

    final double timeWindowSec = recent.length / _measuredHz;
    final double cycles = crossings / 2.0;
    final double freqHz = cycles / timeWindowSec;

    final List<double> intervals = [];
    for (int i = 1; i < crossingIdx.length; i++) {
      intervals.add((crossingIdx[i] - crossingIdx[i - 1]).toDouble());
    }
    final double mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final double variance = intervals
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        intervals.length;
    final double cv = mean > 0 ? sqrt(variance) / mean : 0;

    if (freqHz < 1.0) {
      _logSentinel("SYLVIA RHYTHM: cross=$crossings f=${freqHz.toStringAsFixed(2)}Hz cv=${cv.toStringAsFixed(2)} → NO (freq<1.0)");
      return false;
    }
    if (cv < 0.05 || cv > _cvUpperBound) {
      _logSentinel("SYLVIA RHYTHM: cross=$crossings f=${freqHz.toStringAsFixed(2)}Hz cv=${cv.toStringAsFixed(2)} → NO (cv out of range)");
      return false;
    }

    _logSentinel("SYLVIA RHYTHM: cross=$crossings f=${freqHz.toStringAsFixed(2)}Hz cv=${cv.toStringAsFixed(2)} → YES");
    return true;
  }

  void _enterYellowState() {
    if (_sentinelYellow || _isAlarmActive) return;
    _yellowCountdown = _observationSeconds;
    _logSentinel("SYLVIA SERVICE: 🟡 Impacto detectado. Análisis Smart Sentinel ($_yellowCountdown s)...");
    _sentinelYellow = true;
    _writeWidgetState('yellow');
    service.invoke("sentinelYellow");

    // Phased post-impact analysis (Bourke/Kangas/Musci-style):
    // 1. Settling window (per Musci 2021): movement ignored — could be tumbling,
    //    rolling, failed recovery attempts, secondary impacts.
    // 2. Sustained rhythm check (post-settling): cancellation requires 3 consecutive
    //    2s checks of rhythmic movement (= 6s of cadence-CV-validated gait).
    // 3. Imminent-alert (last 10s): emit sentinelOrange so UI can warn the user.
    final int totalObservation = _observationSeconds;
    final int settlingSeconds = _settlingSeconds;
    const int sustainedRhythmChecks = 3;
    const int orangeWarningSeconds = 10;
    int rhythmStreak = 0;
    bool orangeEmitted = false;

    _yellowTimer?.cancel();
    _yellowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _yellowCountdown -= 2;
      final int elapsed = totalObservation - _yellowCountdown;

      if (!orangeEmitted && _yellowCountdown <= orangeWarningSeconds && _yellowCountdown > 0) {
        orangeEmitted = true;
        _logSentinel("SYLVIA SERVICE: 🟠 Alerta inminente (${_yellowCountdown}s restantes)");
        _writeWidgetState('orange');
        service.invoke("sentinelOrange");
      }

      if (elapsed >= settlingSeconds) {
        if (_isRhythmicMovement()) {
          rhythmStreak++;
          _logSentinel("SYLVIA SERVICE: 🟡 Ritmo detectado ($rhythmStreak/$sustainedRhythmChecks)");
          if (rhythmStreak >= sustainedRhythmChecks) {
            _logSentinel("SYLVIA SERVICE: ✅ Movimiento rítmico sostenido (${sustainedRhythmChecks * 2}s). Falso positivo.");
            _returnToGreen();
            timer.cancel();
            return;
          }
        } else {
          rhythmStreak = 0;
        }
      }

      if (_yellowCountdown <= 0) {
        timer.cancel();
        _returnToGreen();
        if (!_isAlarmActive) {
          _logSentinel("SYLVIA SERVICE: 🔴 Sin movimiento sostenido tras ${totalObservation}s. ACTIVANDO ALARMA.");
          _isAlarmActive = true;
          _lanzarAlarma();
        }
      }
    });
  }

  void _startSensorListener() {
    if (_accSub != null) return;
    _logSentinel("SYLVIA SERVICE: Iniciando escucha de sensores...");

    // Z-only bias tracker. The Pixel 8 z-axis reports a stuck constant (~197 m/s²) that
    // would otherwise dominate magnitude. X and Y on healthy sensors oscillate around 0
    // during rest, so EMA bias on those axes contributes nothing in steady state — but
    // it amplifies transients (e.g. backpack reorientation after sustained walking) by
    // mismatching baseline. Keep filter only where the hardware bug demands it.
    double zBias = 0.0;
    int sensorSamples = 0;
    const double biasAlpha = 0.998;
    final DateTime sensorStreamStart = DateTime.now();
    // Peak watcher state — throttled to one log per 2s.
    DateTime lastPeakLog = DateTime.fromMillisecondsSinceEpoch(0);
    double currentPeakG = 0;
    double currentPeakX = 0, currentPeakY = 0, currentPeakZ = 0;
    // Sample-rate measurement: count packets per 1s window, then publish to
    // _measuredHz so _isRhythmicMovement() can compute frequency correctly
    // regardless of what Android negotiated.
    DateTime hzWindowStart = DateTime.now();
    int hzWindowSamples = 0;
    DateTime lastHzLog = DateTime.fromMillisecondsSinceEpoch(0);

    _accSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((event) {

      if (DateTime.now().difference(_lastStopTimestamp).inSeconds < 10) {
        return;
      }

      if (_isAlarmActive || _sensorCooldown) return;

      sensorSamples++;
      if (sensorSamples == 1) {
        zBias = event.z;
      } else {
        zBias = biasAlpha * zBias + (1 - biasAlpha) * event.z;
      }

      hzWindowSamples++;
      final int hzWindowElapsedMs =
          DateTime.now().difference(hzWindowStart).inMilliseconds;
      if (hzWindowElapsedMs >= 1000) {
        _measuredHz = hzWindowSamples * 1000.0 / hzWindowElapsedMs;
        hzWindowStart = DateTime.now();
        hzWindowSamples = 0;
        if (DateTime.now().difference(lastHzLog).inSeconds >= 30) {
          _logSentinel("SYLVIA HZ: ${_measuredHz.toStringAsFixed(1)} Hz");
          lastHzLog = DateTime.now();
        }
      }

      // Need 100 samples (~2s) AND 4s elapsed before trusting bias-removed signal.
      if (sensorSamples < 100 ||
          DateTime.now().difference(sensorStreamStart).inMilliseconds < 4000) {
        return;
      }

      final double effX = event.x;
      final double effY = event.y;
      final double effZ = event.z - zBias;
      // Full magnitude (with bias-corrected Z) drives impact detection.
      final double userMagnitude = sqrt(effX * effX + effY * effY + effZ * effZ);
      final double instantG = 1.0 + userMagnitude / 9.81;
      // Horizontal-only magnitude drives cadence detection. The Pixel 8 z-axis
      // bias filter introduces asymmetric damping when Z varies during real
      // walking (steps), distorting magnitude and inflating the inter-crossing
      // CV. Walking-in-pocket signal is dominated by lateral sway + fore/aft
      // pitch (XY plane); Z amplitude is heavily damped by fabric anyway.
      // Removing Z from cadence yields a much more uniform CV across devices.
      final double horizontalMagnitude = sqrt(effX * effX + effY * effY);
      final double horizontalG = 1.0 + horizontalMagnitude / 9.81;

      final bool isPaused = _pausedUntil.isAfter(DateTime.now());

      // Peak watcher: track significant motion peaks (above 2.5G) and log the highest
      // every 2s so we can see what "normal use" looks like vs. what triggers the alarm.
      if (instantG > 2.5 && !_sentinelYellow) {
        if (instantG > currentPeakG) {
          currentPeakG = instantG;
          currentPeakX = effX;
          currentPeakY = effY;
          currentPeakZ = effZ;
        }
        if (DateTime.now().difference(lastPeakLog).inSeconds >= 2) {
          _logSentinel("SYLVIA PEAK: ${currentPeakG.toStringAsFixed(2)}G (effX=${currentPeakX.toStringAsFixed(1)} effY=${currentPeakY.toStringAsFixed(1)} effZ=${currentPeakZ.toStringAsFixed(1)})");
          lastPeakLog = DateTime.now();
          currentPeakG = 0;
        }
      }

      if (_isMonitoringImpact && _impactDetectionEnabled && !isPaused) {
        // Buffer holds horizontal G for the cadence detector; impact still uses
        // full instantG (line below). Decoupling the two signals fixes Pixel 8.
        _gBuffer.add(horizontalG);
        // Keep ~3s of margin even at 200Hz (some Pixels deliver that with
        // gameInterval); _isRhythmicMovement only uses last 2s of real samples.
        if (_gBuffer.length > 600) _gBuffer.removeAt(0);

        // Catastrophic impact: skip the yellow observation window. The 30 s
        // pre-alert on AlarmScreen is still the user's chance to cancel.
        if (_orangeThreshold > 0 && instantG >= _orangeThreshold && !_isAlarmActive) {
          _logSentinel("SYLVIA BACKGROUND: 🟠 Impacto crítico ${instantG.toStringAsFixed(2)}G ≥ ${_orangeThreshold}G → ALARMA DIRECTA (effX=${effX.toStringAsFixed(1)} effY=${effY.toStringAsFixed(1)} effZ=${effZ.toStringAsFixed(1)})");
          _activarEscudo(segundos: 3);
          if (_sentinelYellow) {
            _sentinelYellow = false;
            _yellowTimer?.cancel();
            _yellowCountdown = _observationSeconds;
          }
          _lanzarAlarma();
        } else if (instantG > _yellowThreshold && !_sentinelYellow) {
          _logSentinel("SYLVIA BACKGROUND: ⚡ Impacto ${instantG.toStringAsFixed(2)}G → Smart Sentinel (effX=${effX.toStringAsFixed(1)} effY=${effY.toStringAsFixed(1)} effZ=${effZ.toStringAsFixed(1)})");
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
        // Panic widget tap: PanicWidget receiver writes this flag, we trigger
        // the alarm directly. AlarmScreen + 30 s pre-alert remains the safety.
        final int panicReq = prefs.getInt('widget_panic_requested') ?? 0;
        if (panicReq > 0 && !_isAlarmActive) {
          await prefs.setInt('widget_panic_requested', 0);
          _logSentinel("SYLVIA SERVICE: 🆘 Panic widget tapped → ALARMA");
          _activarEscudo(segundos: 3);
          if (_sentinelYellow) {
            _sentinelYellow = false;
            _yellowTimer?.cancel();
            _yellowCountdown = _observationSeconds;
          }
          _lanzarAlarma();
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

      // Smart Beacon: post-SOS position-update protocol.
      _beaconTick();

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
          _scheduleInactivityAlarmClock();
        }
      }
      // Always run the inactivity checker so the panic-widget poll fires even
      // when monitoring is off. Internal guards skip inactivity-specific logic.
      _startInactivityChecker();
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
      _logSentinel("SYLVIA SERVICE: 📥 setMonitoring received: active=${event?['active']} profile=${event?['profile']}");
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

      // Activity profile drives Smart Sentinel parameters at runtime. Read from
      // event when present (UI just toggled), fall back to persisted setting.
      final String profileName = (event != null && event.containsKey('profile'))
          ? event['profile'] as String
          : (prefs.getString('activity_profile') ?? 'trekking');
      final ActivityProfile profile = activityProfileFromName(profileName);
      final ActivityProfileConfig cfg = activityProfileConfigs[profile]!;
      _impactDetectionEnabled = cfg.impactDetectionEnabled;
      if (cfg.impactDetectionEnabled) {
        _yellowThreshold = cfg.yellowThreshold;
        _orangeThreshold = cfg.orangeThreshold;
        _settlingSeconds = cfg.settlingSeconds;
        _observationSeconds = cfg.observationSeconds;
        _cvUpperBound = cfg.cvUpperBound;
      }
      _logSentinel("SYLVIA SERVICE: 🎯 Profile=${profile.name} yellow=${_yellowThreshold}G orange=${_orangeThreshold}G obs=${_observationSeconds}s cv=${_cvUpperBound} impactOn=${_impactDetectionEnabled}");

      print("SYLVIA SERVICE: Monitor - Impact: $_isMonitoringImpact, Inactivity: $_isMonitoringInactivity (Limit: $_inactivityLimitSeconds s)");

      if (_isMonitoringImpact || _isMonitoringInactivity) {
        _activarEscudo(segundos: 4);
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
      _logSentinel("SYLVIA SERVICE: 🛑 Recibida orden de STOP ALARM");

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