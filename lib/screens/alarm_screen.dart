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

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _holdController;
  
  VoidCallback? _statusListener;
  late SOSLogic _logic; 

  @override
  void initState() {
    super.initState();
    
    _logic = context.read<SOSLogic>();
    
    // Círculo visual (decorativo)
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _logic.currentCountdownSeconds),
    )..reverse(from: 1.0);

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), 
    );

    // Cancelar
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSuccessHaptic();
        _logic.cancelSOS();
      }
    });

    // Cerrar automáticamente si se envía o se cancela
    _statusListener = () {
      if (!mounted) return;
      final currentStatus = _logic.status;
      
      if (currentStatus == SOSStatus.sent || currentStatus == SOSStatus.ready) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    };
    
    _logic.addListener(_statusListener!);
  }

  Future<void> _triggerSuccessHaptic() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 50, 50]); 
    }
  }

  @override
  void dispose() {
    if (_statusListener != null) {
      _logic.removeListener(_statusListener!);
    }
    _countdownController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos actualizaciones de segundos
    final logic = context.watch<SOSLogic>();
    final l10n = AppLocalizations.of(context)!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFB71C1C);
    final Color textColor = Colors.white;

    String titleText = "SOS";
    String bodyText = l10n.alertSendingIn;

    if (logic.lastTrigger == AlertCause.fall) {
      titleText = l10n.alertFallDetected;
      bodyText = l10n.alertFallBody;
    } else if (logic.lastTrigger == AlertCause.inactivity) {
      titleText = l10n.alertInactivityDetected;
      bodyText = l10n.alertInactivityBody;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.warning_amber_rounded, size: 60, color: textColor),
                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      bodyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // RELOJ
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: AnimatedBuilder(
                          animation: _countdownController,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _countdownController.value,
                              strokeWidth: 12,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            );
                          },
                        ),
                      ),
                      // TEXTO DIRECTO DE LA LÓGICA
                      Text(
                        '${logic.currentCountdownSeconds}',
                        style: TextStyle(
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),

                  // BOTÓN DE SEGURIDAD
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (_) => _holdController.forward(),
                    onPanEnd: (_) {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reverse();
                      }
                    },
                    onPanCancel: () => _holdController.reverse(),
                    
                    child: Container(
                      width: 200,
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: AnimatedBuilder(
                                  animation: _holdController,
                                  builder: (context, child) {
                                    return CircularProgressIndicator(
                                      value: _holdController.value,
                                      strokeWidth: 10,
                                      backgroundColor: Colors.white10,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), 
                                      blurRadius: 15, 
                                      spreadRadius: 2
                                    )
                                  ]
                                ),
                                child: Center(
                                  child: Icon(Icons.stop_rounded, color: bgColor, size: 50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            l10n.alertCancel.toUpperCase(), 
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "(${l10n.holdToCancel})",
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}