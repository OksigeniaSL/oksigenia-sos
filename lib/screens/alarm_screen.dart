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
  // TalkBack sends one long-press action, never a held finger: without this a
  // screen-reader user could not cancel a false alarm.
  bool _a11yHold = false;

  @override
  void initState() {
    super.initState();
    
    _logic = context.read<SOSLogic>();
    
    double totalSeconds = 30.0; 
    double remaining = _logic.currentCountdownSeconds.toDouble();
    double startValue = (remaining / totalSeconds).clamp(0.0, 1.0);

    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds.toInt()),
    )..reverse(from: startValue); 

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), 
    );

    // Cancelar
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        debugPrint("ALARM SCREEN: Botón completado. Cancelando...");
        _a11yHold = false;
        _triggerSuccessHaptic();
        _logic.cancelSOS();
      }
    });

    // Cerrar automáticamente si se envía o se cancela. scanning y error NO
    // cierran: la pantalla los renderiza ("Enviando…" / fallo con reintento).
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
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 50, 50, 50]); 
      }
    } catch (e) {
      debugPrint("Error vibración: $e");
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
    final logic = context.watch<SOSLogic>();
    final l10n = AppLocalizations.of(context)!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFB71C1C);
    final Color textColor = Colors.white;

    final bool isSending = logic.status == SOSStatus.scanning;
    final bool isError = logic.status == SOSStatus.error;

    String titleText = "SOS";
    String bodyText = l10n.alertSendingIn;

    if (logic.lastTrigger == AlertCause.fall) {
      titleText = l10n.alertFallDetected;
      bodyText = l10n.alertFallBody;
    } else if (logic.lastTrigger == AlertCause.inactivity) {
      titleText = l10n.alertInactivityDetected;
      bodyText = l10n.alertInactivityBody;
    }

    if (isError) {
      titleText = l10n.alarmSendFailed;
      bodyText = l10n.statusSendFailedBody;
    } else if (isSending) {
      bodyText = l10n.alarmSendingNow;
    }

    final mq = MediaQuery.of(context);
    // Short screens (360×640 and similar): with the cancel control pinned at
    // the bottom, the full-size countdown ended up hidden behind it.
    final bool compact = mq.size.height < 700;
    final double ring = compact ? 120 : 180;
    final double holdRing = compact ? 110 : 150;
    final double holdButton = compact ? 60 : 80;
    // With a large system font (360×640 at 150-200 %) the cancel control ended
    // up off screen, and the screen could not scroll: no way to stop a false
    // alarm. The scale is capped on this one screen, the content scrolls, and
    // the cancel control stays pinned at the bottom, outside the scroll, so a
    // shaky hold is never taken for a drag.
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
      backgroundColor: bgColor,
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  SizedBox(height: compact ? 8 : 20),
                  Icon(Icons.warning_amber_rounded, size: compact ? 40 : 60, color: textColor),
                  SizedBox(height: compact ? 6 : 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: compact ? 22 : 26,
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
                  SizedBox(height: compact ? 12 : 30),

                  // RELOJ — o spinner de envío / icono de fallo según estado
                  if (isError)
                    Icon(Icons.sms_failed_rounded, size: compact ? 72 : 120, color: textColor)
                  else if (isSending)
                    SizedBox(
                      width: ring,
                      height: ring,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 12,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The seconds are read from the number; the ring's
                        // percentage only confused screen readers.
                        ExcludeSemantics(
                         child: SizedBox(
                          width: ring,
                          height: ring,
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
                        ),
                        // TEXTO DIRECTO DE LA LÓGICA
                        Text(
                          '${logic.currentCountdownSeconds}',
                          style: TextStyle(
                            fontSize: compact ? 48 : 70,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: compact ? 16 : 40),

                  if (isError) ...[
                    ElevatedButton.icon(
                      onPressed: () => logic.sendSOS(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.btnRetry.toUpperCase()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB71C1C),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                      ],
                    ),
                  ),
                ),
              ),
                  // BOTÓN DE SEGURIDAD
                  Semantics(
                    container: true,
                    button: true,
                    liveRegion: true,
                    label: l10n.alertCancel,
                    value: _a11yHold ? l10n.a11yAlarmCancelCountdown : null,
                    hint: l10n.a11yAlarmCancelHint,
                    onLongPressHint: l10n.a11yAlarmCancelLongPress,
                    onLongPress: () {
                      setState(() => _a11yHold = true);
                      _holdController.forward();
                    },
                    onTap: _a11yHold
                        ? () {
                            setState(() => _a11yHold = false);
                            _holdController.reverse();
                          }
                        : null,
                    excludeSemantics: true,
                    child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (_) {
                      debugPrint("ALARM SCREEN: Botón presionado");
                      if (_a11yHold) setState(() => _a11yHold = false);
                      _holdController.forward();
                    },
                    onPanEnd: (_) {
                      if (_holdController.status != AnimationStatus.completed) {
                        debugPrint("ALARM SCREEN: Botón soltado antes de tiempo");
                        _holdController.reverse();
                      }
                    },
                    onPanCancel: () {
                      debugPrint("ALARM SCREEN: Gesto cancelado");
                      _holdController.reverse();
                    },
                    
                    child: Container(
                      width: 200,
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: holdRing,
                                height: holdRing,
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
                                width: holdButton,
                                height: holdButton,
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
                                  child: Icon(Icons.stop_rounded, color: bgColor, size: compact ? 38 : 50),
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
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ));
  }
}