import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:vibration/vibration.dart'; 

const String channelId = 'my_foreground'; 
const int notificationId = 888;

final AudioPlayer _audioPlayer = AudioPlayer();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    'Oksigenia SOS - Active Monitor',
    description: 'Monitorización activa de seguridad',
    importance: Importance.high, 
    playSound: false,
    enableVibration: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, 
      isForegroundMode: true,
      notificationChannelId: channelId,
      initialNotificationTitle: 'Oksigenia SOS',
      initialNotificationContent: 'System Ready',
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [
        AndroidForegroundType.location,
        AndroidForegroundType.dataSync,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_protected'); 
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  try {
    await _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm,
        audioFocus: AndroidAudioFocus.gainTransient,
      ),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
    ));
  } catch (e) {
    print("SYLVIA: Error audio context: $e");
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
        print("SYLVIA: 💀 Recibida orden de apagado. Bye.");
        _audioPlayer.stop();
        _audioPlayer.dispose();
        service.stopSelf();
    });

    service.on('startAlarm').listen((event) async {
      try {
        service.setAsForegroundService();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
        if (await Vibration.hasVibrator() ?? false) {
           Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
        }
      } catch (e) { print("Error alarma: $e"); }
    });

    service.on('stopAlarm').listen((event) async {
      try {
        await _audioPlayer.stop();
        Vibration.cancel();
      } catch (e) { print("Error stop: $e"); }
    });

    service.on('updateNotification').listen((event) async {
      if (event == null) return;

      String status = event['status'] ?? 'active';
      String title = event['title'] ?? 'Oksigenia SOS';
      String content = event['content'] ?? 'Active Monitor';

      // 🟢 ICONOS REALES
      String iconName = 'ic_stat_protected'; 
      
      if (status == 'paused') {
        iconName = 'ic_stat_paused'; 
      } else if (status == 'alarm') {
        iconName = 'ic_stat_protected'; 
      }

      // 🟢 ZOMBIE KILLER: 
      // ongoing = false permite al sistema matar la notificación al cerrar la app.
      bool isOngoing = false; 

      if (status == 'alarm') {
        isOngoing = true; // Solo fija en emergencia
      }

      try {
        await flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: title,       
          body: content,      
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              'Oksigenia SOS - Active Monitor',
              icon: iconName,
              ongoing: isOngoing, 
              importance: Importance.high,
              priority: Priority.high,
              onlyAlertOnce: true, 
              playSound: false,
              enableVibration: false,
              showWhen: false,
              autoCancel: false,
            ),
          ),
        );
      } catch (e) {
        print("SYLVIA ERROR: Fallo notificación: $e");
      }
    });
  }
}