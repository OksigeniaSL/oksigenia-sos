import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/logic/sos_logic.dart';
import 'package:oksigenia_sos/widgets/main_drawer.dart';
import 'package:oksigenia_sos/services/remote_config_service.dart';
import 'package:oksigenia_sos/screens/update_screen.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final SOSLogic _sosLogic = SOSLogic();
  bool _hasShownWarning = false;
  
  late AnimationController _sosHoldController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
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
      print("🔄 APP RESUMED: Verificando servicio tras volver de ajustes...");
      FlutterBackgroundService().isRunning().then((isRunning) {
        if (!isRunning) {
          FlutterBackgroundService().startService();
        } else {
           FlutterBackgroundService().invoke("updateLanguage");
        }
      });
      _sosLogic.init(); 
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosHoldController.dispose();
    _sosLogic.dispose();
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
      return _buildSentUI(context);
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
                  Column(
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
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==========================================================
            // BOTÓN SOS
            // ==========================================================
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (_) {
                // 🛑 COMPROBACIÓN DE CONTACTO
                if (_sosLogic.emergencyContact == null) {
                  _triggerErrorHaptic();
                  
                  // Limpiamos cualquier snackbar anterior para que no se acumulen
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  // Mostramos el aviso MEJORADO
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.errorNoContact, // Usa la variable de localización
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, // Texto en negrita para mejor lectura
                                fontSize: 15
                              )
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent.shade700, // Rojo un poco más oscuro para contraste
                      behavior: SnackBarBehavior.floating, // Flotante (no pegado abajo)
                      margin: const EdgeInsets.all(16), // Margen alrededor
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Redondeado
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: l10n.menuSettings.toUpperCase(),
                        textColor: Colors.white,
                        backgroundColor: Colors.white24, // Fondo suave para el botón
                        onPressed: () {
                          // Limpiamos el mensaje AL PULSAR para que no te persiga a la otra pantalla
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
            // ==========================================================

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

            // INTERRUPTORES MEJORADOS (Texto más grande y visible)
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
            
            // MENSAJES DE ERROR
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
    // Detectamos tema para mejorar contraste
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      child: SwitchListTile(
        title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500) // Título un poco más fuerte
        ), 
        subtitle: subtitle != null ? Text(
            subtitle, 
            style: TextStyle(
                // Color más fuerte: Blanco en dark mode, Gris oscuro en light mode
                color: isDark ? Colors.white70 : Colors.grey[800], 
                fontSize: 14, // Aumentado de 12 a 14
                fontWeight: FontWeight.bold // Negrita para la presbicia
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

  Widget _buildSentUI(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3), 
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 40),
              
              Text(
                l10n.statusSent, 
                textAlign: TextAlign.center, 
                style: const TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                )
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                "Monitor detenido / Monitor stopped.\nPantalla apagada en breve / Screen sleeping soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sosLogic.cancelAlert, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    foregroundColor: const Color(0xFF1976D2), 
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ), 
                  child: const Text(
                    "REINICIAR SISTEMA", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  )
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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