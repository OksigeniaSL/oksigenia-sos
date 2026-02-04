import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/logic/sos_logic.dart';
import 'package:oksigenia_sos/widgets/main_drawer.dart';
import 'package:oksigenia_sos/services/remote_config_service.dart';
import 'package:oksigenia_sos/screens/update_screen.dart';
import 'package:oksigenia_sos/screens/sent_screen.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late SOSLogic _sosLogic; 
  bool _hasShownWarning = false;
  late AnimationController _sosHoldController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
    // 🧠 CONEXIÓN AL CEREBRO GLOBAL (PROVIDER)
    _sosLogic = context.read<SOSLogic>();
    
    // Inicializamos lógica y wakelock
    _sosLogic.init();
    WakelockPlus.enable();
    
    // Configuración del botón SOS (3 segundos para activar)
    _sosHoldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), 
    );

    _sosHoldController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerHaptic();
        _sosHoldController.reset();
        _sosLogic.sendSOS();
      }
    });
    
    // BACKUP DE SEGURIDAD
    Future.delayed(const Duration(seconds: 1), () {
      FlutterBackgroundService().isRunning().then((isRunning) {
        if (!isRunning) {
          print("SYLVIA: Arrancando servicio forzosamente desde UI");
          FlutterBackgroundService().startService();
        }
      });
    });

    _checkRemoteConfig();
  }

  Future<void> _triggerHaptic() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 50, 50]);
    }
  }

  Future<void> _triggerErrorHaptic() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 50, 50, 50, 50]);
    }
  }

  void _checkRemoteConfig() async {
    final result = await RemoteConfigService().checkStatus();
    if (!mounted) return;

    if (result['block'] == true) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => UpdateScreen(updateUrl: result['update_url']))
      );
      return;
    }

    String msgEs = result['message_es'] ?? "";
    if (msgEs.isNotEmpty && !msgEs.contains("Sistema Oksigenia SOS Activo")) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("📢 $msgEs"),
           backgroundColor: Colors.blue[800],
           duration: const Duration(seconds: 5),
           action: SnackBarAction(label: "OK", textColor: Colors.white, onPressed: (){}),
         )
       );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🛡️ PROTECCIÓN CRÍTICA (EL BLINDAJE):
      // Si estamos en medio de una ALARMA (preAlert) o ENVIADO (sent),
      // NO reiniciamos la lógica. Dejamos que el proceso siga su curso.
      if (_sosLogic.status == SOSStatus.preAlert || _sosLogic.status == SOSStatus.sent) {
        print("🔄 APP RESUMED: Ignorando reinicio porque hay una EMERGENCIA en curso.");
        return;
      }

      print("🔄 APP RESUMED: Verificando servicio tras volver de ajustes...");
      FlutterBackgroundService().isRunning().then((isRunning) {
        if (!isRunning) {
          FlutterBackgroundService().startService();
        } else {
           FlutterBackgroundService().invoke("updateLanguage");
        }
      });
      // Aseguramos que la lógica está despierta (Solo si no hay emergencia)
      _sosLogic.init(); 
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosHoldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sosLogic,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.appTitle),
            centerTitle: true,
            elevation: 0,
          ),
          drawer: MainDrawer(sosLogic: _sosLogic),
          body: _buildBody(context),
        );
      }
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_sosLogic.status == SOSStatus.sent) {
      return SentScreen();
    }

    final l10n = AppLocalizations.of(context)!;

    Color gForceColor = Colors.grey; 
    double g = _sosLogic.currentGForce;

    if (g > 0.0) { 
      if (g <= 1.05) {
        gForceColor = Colors.green;   
      } else if (g > 1.05 && g <= 2.0) {
        gForceColor = Colors.yellow;  
      } else if (g > 2.0 && g <= 8.0) {
        gForceColor = Colors.orange;  
      } else {
        gForceColor = Colors.red;     
      }
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // STATUS PILL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _sosLogic.status == SOSStatus.locationFixed 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _sosLogic.status == SOSStatus.locationFixed 
                      ? Colors.green 
                      : Colors.grey
                )
              ),
              child: Text(
                _sosLogic.status == SOSStatus.locationFixed 
                    ? l10n.statusLocationFixed 
                    : (_sosLogic.status == SOSStatus.scanning 
                        ? l10n.statusConnecting 
                        : l10n.statusReady),
                style: TextStyle(
                  color: _sosLogic.status == SOSStatus.locationFixed ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            
            const SizedBox(height: 25),

            // HEALTH DASHBOARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // G-Force
                  Column(
                    children: [
                      Icon(Icons.speed, color: gForceColor, size: 48),
                      const SizedBox(height: 6),
                      Text(
                        "${_sosLogic.currentGForce.toStringAsFixed(2)}G",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ],
                  ),

                  // Batería
                  Column(
                    children: [
                      Icon(
                        _sosLogic.batteryLevel > 20 ? Icons.battery_std : Icons.battery_alert, 
                        color: _sosLogic.batteryLevel > 20 ? Colors.green : Colors.red, 
                        size: 48 
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_sosLogic.batteryLevel}%", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ],
                  ),

                  // GPS (INTERACTIVO - MANTENIDO)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 10),
                              Text(l10n.gpsHelpTitle),
                            ],
                          ),
                          content: Text(l10n.gpsHelpBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("OK"),
                            )
                          ],
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.gps_fixed, 
                          color: _sosLogic.gpsAccuracy > 0 ? Colors.green : Colors.grey, 
                          size: 48
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _sosLogic.gpsAccuracy > 0 ? "${_sosLogic.gpsAccuracy.toStringAsFixed(0)}m" : "--", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // BOTÓN SOS
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (_) {
                if (_sosLogic.emergencyContact == null) {
                  _triggerErrorHaptic();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.errorNoContact,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent.shade700,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: l10n.menuSettings.toUpperCase(),
                        textColor: Colors.white,
                        backgroundColor: Colors.white24,
                        onPressed: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          _sosLogic.openSettings(context);
                        }
                      ),
                    )
                  );
                  return; 
                }
                _sosHoldController.forward();
              },
              onPanEnd: (_) {
                if (_sosHoldController.status != AnimationStatus.completed) {
                  _sosHoldController.reverse();
                }
              },
              onPanCancel: () => _sosHoldController.reverse(),
              
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _sosHoldController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _sosHoldController.value,
                          strokeWidth: 10,
                          backgroundColor: Colors.transparent, 
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        );
                      },
                    ),
                  ),

                  Center(
                    child: Text(
                      l10n.sosButton,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "${l10n.toastHoldToSOS} (3s)", 
              style: const TextStyle(color: Colors.grey)
            ),
            
            const SizedBox(height: 30),

            // AVISO MODO TEST
            if (_sosLogic.currentInactivityLimit == 30) 
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 30, right: 30),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.testModeWarning, 
                          style: const TextStyle(color: Colors.black87, fontSize: 13)
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // INTERRUPTORES
            _buildQuickToggle(
              context, 
              l10n.autoModeLabel, 
              _sosLogic.isFallDetectionActive, 
              (v) {
                _sosLogic.toggleFallDetection(v);
                if (v && !_hasShownWarning) {
                   _showKeepAliveWarning(context, l10n);
                   _hasShownWarning = true;
                }
              },
              Icons.directions_run
            ),
            _buildQuickToggle(
              context, 
              l10n.inactivityModeLabel, 
              _sosLogic.isInactivityMonitorActive, 
              (v) {
                _sosLogic.toggleInactivityMonitor(v);
                if (v && !_hasShownWarning) {
                   _showKeepAliveWarning(context, l10n);
                   _hasShownWarning = true;
                }
              },
              Icons.accessibility_new,
              subtitle: _sosLogic.isInactivityMonitorActive 
                  ? "${l10n.timerLabel}: ${_sosLogic.currentInactivityLimit < 60 ? '${_sosLogic.currentInactivityLimit} ${l10n.timerSeconds}' : '${_sosLogic.currentInactivityLimit ~/ 3600} h'}" 
                  : null
            ),
            
            if (_sosLogic.status == SOSStatus.error) ...[
               const SizedBox(height: 20),
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Text(
                      _sosLogic.errorMessage == "NO_CONTACT" 
                          ? l10n.errorNoContact 
                          : _sosLogic.errorMessage, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 10),
                    if (_sosLogic.errorMessage == "NO_CONTACT" || _sosLogic.errorMessage.contains("Configura")) 
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: Text(l10n.menuSettings.toUpperCase()),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        onPressed: () => _sosLogic.openSettings(context),
                      )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToggle(BuildContext context, String label, bool value, Function(bool) onChanged, IconData icon, {String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)), 
        subtitle: subtitle != null ? Text(
            subtitle, 
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[800], 
                fontSize: 14, 
                fontWeight: FontWeight.bold
            )
        ) : null,
        secondary: Icon(icon, color: value ? Colors.redAccent : Colors.grey),
        value: value, 
        onChanged: (newValue) async {
          if (newValue) {
            bool restricted = await _sosLogic.arePermissionsRestricted();
            if (restricted) {
               if (mounted) _showRestrictedDialog(context);
               return; 
            }
          }
          onChanged(newValue);
        },
        activeColor: Colors.redAccent,
      ),
    );
  }

  void _showRestrictedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text("Permisos Bloqueados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Android ha restringido los permisos de seguridad (SMS o GPS).",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings(); 
              },
              child: const Text("IR A AJUSTES"),
            )
          ],
        ),
      ),
    );
  }

  void _showKeepAliveWarning(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.warningKeepAlive, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: "OK",
          textColor: Colors.white,
          onPressed: () {
             ScaffoldMessenger.of(context).clearSnackBars();
          },
        ),
      ),
    );
  }
}