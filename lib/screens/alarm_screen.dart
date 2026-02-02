import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oksigenia_sos/logic/sos_logic.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart'; 

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    final logic = context.read<SOSLogic>();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: logic.currentCountdownSeconds), 
    )..reverse(from: 1.0);

    _startAlarmFeedback();
  }

  void _startAlarmFeedback() {
    _triggerFeedback();
    _feedbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _triggerFeedback();
    });
  }

  Future<void> _triggerFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para reconstruir si cambia el estado
    final logic = context.watch<SOSLogic>();
    final l10n = AppLocalizations.of(context)!;

    // Si se cancela, cerrar
    if (logic.status == SOSStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    // 1. DETERMINAR TEXTOS SEGÚN LA CAUSA (Sin hardcode)
    String titleText;
    String bodyText;

    if (logic.lastTrigger == AlertCause.fall) {
      titleText = l10n.alertFallDetected; // "IMPACT DETECTED!"
      bodyText = l10n.alertFallBody;      // "Severe fall detected..."
    } else if (logic.lastTrigger == AlertCause.inactivity) {
      titleText = l10n.alertInactivityDetected; // "INACTIVITY DETECTED!"
      bodyText = l10n.alertInactivityBody;      // "No movement detected..."
    } else {
      // Fallback para manual u otros
      titleText = "SOS";
      bodyText = l10n.alertSendingIn;
    }

    return Scaffold(
      backgroundColor: Colors.redAccent, 
      body: PopScope(
        canPop: false, 
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONO DE ALERTA
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 20),

              // 2. TÍTULO (Traducido)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. CUERPO (Traducido)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  bodyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // CÍRCULO DE CUENTA ATRÁS
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _controller.value, 
                      strokeWidth: 15,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      backgroundColor: Colors.black12,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      int secs = (_controller.duration!.inSeconds * _controller.value).ceil();
                      return Text(
                        '$secs',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // BOTÓN CANCELAR
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    logic.cancelSOS(); 
                  },
                  child: Text(
                    l10n.alertCancel.toUpperCase(), 
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}