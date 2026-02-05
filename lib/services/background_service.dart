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
    importance: Importance.high, // 🔥 High para icono visible
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
      autoStart: true, 
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
      autoStart: true,
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
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: InitializationSettings(android: initializationSettingsAndroid),
  );

  // --- AUDIO ---
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
  
    service.on('stopService').listen((event) {
        _audioPlayer.stop();
        service.stopSelf();
    });

    // --- LISTENER ACTUALIZADO (Con sintaxis corregida) ---
    service.on('updateNotification').listen((event) async {
      if (event == null) return;

      String status = event['status'] ?? 'active';
      String title = event['title'] ?? 'Oksigenia SOS';
      String content = event['content'] ?? 'Active Monitor';

      String iconName = 'ic_stat_protected';
      if (status == 'paused') {
        iconName = 'ic_stat_paused';
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
              ongoing: true,
              importance: Importance.high, // 🔥 ASEGURA ICONO
              priority: Priority.high,
              onlyAlertOnce: true, // 🔥 EVITA QUE SALTE LA CORTINILLA
              playSound: false,
              enableVibration: false,
              showWhen: false,
              autoCancel: false,
            ),
          ),
        );
      } catch (e) {
        print("SYLVIA ERROR: No se pudo actualizar la notificación: $e");
      }
    });
  }
}