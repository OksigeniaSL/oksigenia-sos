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

const String channelId = 'my_foreground';
const int notificationId = 888;

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
  'smsDyingGasp': 'BATTERY CRITICAL. Bye.'
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
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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

  bool _sensorCooldown = false;
  const double _impactThreshold = 12.0;
  double _lastG = 1.0;
  
  // 🟢 FIX: Marca de tiempo al iniciar el servicio
  final DateTime serviceStartupTime = DateTime.now();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_protected');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

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
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient),
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
    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;
    } catch (_) {}
  }

  Future<void> _reproducirConfirmacion() async {
    try {
      await _audioPlayer?.stop();
      _audioPlayer = AudioPlayer(); // Nuevo player para el beep
      await _audioPlayer!.setVolume(1.0);
      await _audioPlayer!.play(AssetSource('sounds/send.mp3'));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 2. FUNCIONES AUXILIARES
  // ---------------------------------------------------------------------------

  void _activarEscudo({int segundos = 3}) {
    print("SYLVIA SERVICE: 🛡️ Activando escudo por $segundos segundos...");
    _sensorCooldown = true;
    Future.delayed(Duration(seconds: segundos), () => _sensorCooldown = false);
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
      print("SYLVIA: Obteniendo posición GPS crítica...");
      Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      
      msgBody += "\nMaps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      msgBody += "\nOSM: https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}";
      msgBody += "\n\n🔋Bat: $batteryLevel% | 📡Alt: ${pos.altitude.toStringAsFixed(0)}m | 🎯Acc: ${pos.accuracy.toStringAsFixed(0)}m";
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_alarm_active', true);
      await prefs.setInt('alarm_start_timestamp', DateTime.now().millisecondsSinceEpoch);

      try {
        await platform.invokeMethod('wakeScreen');
        await platform.invokeMethod('bringToFront'); 
      } catch (_) {}

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
          id: notificationId,
          title: "${_texts['alertSendingIn']} $_zombieCountdown s",
          body: _texts['holdToCancel'],
          notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                  channelId, 'Oksigenia SOS - Active Monitor',
                  icon: 'ic_stat_protected',
                  ongoing: true,
                  importance: Importance.max,
                  priority: Priority.max,
                  color: const Color(0xFFFF0000),
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

          flutterLocalNotificationsPlugin.show(
            id: notificationId,
            title: _texts['statusSent'],
            body: _texts['statusReady'],
            notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                    channelId, 'Oksigenia SOS',
                    icon: 'ic_stat_protected',
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

      if (_isMonitoringImpact && instantG > _impactThreshold) {
        print("SYLVIA BACKGROUND: 💥 CAÍDA DETECTADA ($instantG G)");
        _activarEscudo(segundos: 5);
        _isAlarmActive = true;
        _lanzarAlarma();
        return;
      }

      if (_isMonitoringInactivity) {
        double delta = (instantG - _lastG).abs();
        if (delta > 0.15 || instantG > 1.15 || instantG < 0.85) {
          _lastMovementTime = DateTime.now(); 
        }
        _lastG = instantG;
      }
    });
  }

  void _startInactivityChecker() {
    _inactivityCheckTimer?.cancel();
    _inactivityCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      
      if (DateTime.now().difference(_lastStopTimestamp).inSeconds < 10) {
        return;
      }

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

      print("SYLVIA BOOT: Contactos: ${_recipients.length}, Fall: $savedFall, Inactivity: $savedInactivity");

      flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: 'Oksigenia SOS',
          body: 'System Ready',
          notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                  channelId, 'Oksigenia SOS - Active Monitor',
                  icon: 'ic_stat_protected',
                  ongoing: true,
                  importance: Importance.high,
                  priority: Priority.high))
      );

      if (savedFall || savedInactivity) {
        _isMonitoringImpact = savedFall;
        _isMonitoringInactivity = savedInactivity;
        _startSensorListener();
        if (_isMonitoringInactivity) _startInactivityChecker();
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
      await _detenerSonido();
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
        } else {
          _inactivityCheckTimer?.cancel();
        }
      } else {
        _accSub?.cancel();
        _accSub = null;
        _inactivityCheckTimer?.cancel();
      }
    });

    service.on('startAlarm').listen((event) => _lanzarAlarma());

    service.on('stopAlarm').listen((event) async {
      print("SYLVIA SERVICE: 🛑 Recibida orden de STOP ALARM");
      
      _lastStopTimestamp = DateTime.now();
      
      _isAlarmActive = false;
      _activarEscudo(segundos: 4);
      _zombieTimer?.cancel();
      
      _lastMovementTime = DateTime.now().add(const Duration(seconds: 15));

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_alarm_active', false);
        await _detenerSonido();
        Vibration.cancel();
        
        flutterLocalNotificationsPlugin.show(
            id: notificationId,
            title: "Oksigenia SOS",
            body: _texts['statusReady'],
            notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                    channelId, 'Oksigenia SOS - Active Monitor',
                    icon: 'ic_stat_protected',
                    ongoing: true,
                    importance: Importance.high,
                    priority: Priority.high)));
      } catch (e) {
        print("Error stop: $e");
      }
    });

    service.on('updateNotification').listen((event) async {
      if (event == null) return;
      String status = event['status'] ?? 'active';
      String title = event['title'] ?? 'Oksigenia SOS';
      String content = event['content'] ?? 'Active Monitor';
      String iconName = 'ic_stat_protected';
      if (status == 'paused') iconName = 'ic_stat_paused';
      if (status == 'alarm') iconName = 'ic_stat_protected';

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