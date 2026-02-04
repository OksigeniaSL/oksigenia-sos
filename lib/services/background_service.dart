import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; // <--- NECESARIO PARA GRITAR
import 'package:vibration/vibration.dart';       // <--- NECESARIO PARA VIBRAR

// 🧠 MEMORIA DE SYLVIA
String? _lastContent;
// 🔊 LAS CUERDAS VOCALES (Variable global del Isolate)
final AudioPlayer _audioPlayer = AudioPlayer();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true, 
      isForegroundMode: false, 
      notificationChannelId: 'oksigenia_sos_modular_v1',       
      initialNotificationTitle: 'OKSIGENIA SOS',
      initialNotificationContent: 'Iniciando...',
      foregroundServiceTypes: [
        AndroidForegroundType.location,
        AndroidForegroundType.dataSync,
        AndroidForegroundType.mediaPlayback, // <--- Añadido para garantizar audio
      ],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Configuración inicial del Audio (Contexto de Alarma)
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
    print("SYLVIA: Error configurando audio context: $e");
  }

  if (service is AndroidServiceInstance) {
    // 1. AUTO-PROMOCIÓN AL INICIO
    Timer(const Duration(seconds: 1), () async {
      await _updateNotificationText(service, force: true); 
      service.setAsForegroundService();
      print("SYLVIA: Uniforme puesto al arrancar.");
    });

    // --- 👂 OÍDOS DE SYLVIA (ESCUCHAR ÓRDENES) ---

    // A. ORDEN DE GRITAR (ALARMA)
    service.on('startAlarm').listen((event) async {
      print("SYLVIA: 🚨 RECIBIDA ORDEN DE ALARMA -> ACTIVANDO SONIDO Y VIBRACIÓN");
      try {
        // Aseguramos que es Foreground para tener prioridad de CPU
        service.setAsForegroundService();
        
        // Loop de sonido
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
        
        // Loop de vibración (SOS agresivo)
        if (await Vibration.hasVibrator() ?? false) {
           Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
        }
      } catch (e) {
        print("SYLVIA: ❌ Error crítico activando alarma: $e");
      }
    });

    // B. ORDEN DE CALLAR (STOP)
    service.on('stopAlarm').listen((event) async {
      print("SYLVIA: 🔇 RECIBIDA ORDEN DE SILENCIO");
      try {
        await _audioPlayer.stop();
        Vibration.cancel();
      } catch (e) {
        print("SYLVIA: Error parando alarma: $e");
      }
    });

    // C. CAMBIOS DE IDIOMA
    service.on('updateLanguage').listen((event) async {
      print("SYLVIA: Recibida orden de cambio de idioma.");
      await _updateNotificationText(service, force: true);
    });

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    _audioPlayer.stop(); // Nos aseguramos de callar antes de morir
    service.stopSelf();
  });

  // 3. PULSO CARDÍACO (60s)
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      bool isForeground = await service.isForegroundService();
      if (!isForeground) {
        print("SYLVIA: Recuperando rango...");
        service.setAsForegroundService();
        await _updateNotificationText(service, force: true);
      } else {
        await _updateNotificationText(service, force: false);
      }
    }
  });
}

// 🧠 FUNCIÓN OPTIMIZADA: Solo notifica si hay cambios
Future<void> _updateNotificationText(AndroidServiceInstance service, {bool force = false}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); 
    final langCode = prefs.getString('language_code') ?? 'es';
    
    String title = "Oksigenia SOS";
    String content = "Protección activada"; 

    if (langCode == 'en') { content = "Protection active"; }
    else if (langCode == 'fr') { content = "Protection active"; }
    else if (langCode == 'pt') { content = "Proteção ativa"; }
    else if (langCode == 'de') { content = "Schutz aktiv"; }
    else if (langCode == 'it') { content = "Protezione attiva"; }
    else if (langCode == 'nl') { content = "Beveiliging actief"; }
    else if (langCode == 'sv') { content = "Skydd aktivt"; }

    if (!force && content == _lastContent) {
      return; 
    }

    _lastContent = content;

    service.setForegroundNotificationInfo(
      title: title,
      content: content,
    );
    // print("SYLVIA: Notificación actualizada a ($langCode)"); // Comentado para no saturar log
    
  } catch (e) {
    print("SYLVIA ERROR al traducir: $e");
  }
}