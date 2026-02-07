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
    
    _sosLogic = context.read<SOSLogic>();
    _sosLogic.init();
    WakelockPlus.enable();
    
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
    
    Future.delayed(const Duration(seconds: 1), () {
      FlutterBackgroundService().isRunning().then((isRunning) {
        if (!isRunning) {
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
      if (_sosLogic.status == SOSStatus.preAlert || _sosLogic.status == SOSStatus.sent) return;

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
    WakelockPlus.disable(); 
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

    // --- VISUAL FUERZA G ---
    Color gForceColor = Colors.grey; 
    IconData gForceIcon = Icons.speed;
    String gForceText = "${_sosLogic.currentGForce.toStringAsFixed(2)}G";

    if (!_sosLogic.sensorsPermissionOk) {
      gForceColor = Colors.redAccent;
      gForceIcon = Icons.warning_amber_rounded;
      gForceText = "---";
    } else {
      double g = _sosLogic.currentGForce;
      if (g > 0.0) { 
        if (g <= 1.05) gForceColor = Colors.green;   
        else if (g > 1.05 && g <= 2.0) gForceColor = Colors.yellow;  
        else if (g > 2.0 && g <= 8.0) gForceColor = Colors.orange;  
        else gForceColor = Colors.red;     
      }
    }

    // --- VISUAL BATERÍA ---
    Color battColor = _sosLogic.batteryLevel > 20 ? Colors.green : Colors.red;
    IconData battIcon = _sosLogic.batteryLevel > 20 ? Icons.battery_std : Icons.battery_alert;
    
    if (!_sosLogic.batteryOptimizationOk) {
       battColor = Colors.orange; 
       battIcon = Icons.battery_alert;
    }

    // --- VISUAL SEMÁFOROS (HEADER) ---
    bool hasContacts = _sosLogic.emergencyContact != null;
    Color contactColor = hasContacts ? Colors.green : Colors.red;
    Color smsColor = _sosLogic.smsPermissionOk ? Colors.green : Colors.red;
    Color notifColor = _sosLogic.notificationPermissionOk ? Colors.green : Colors.red;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            // 🚥 SEMÁFORO DE PERMISOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. SMS
                  _buildStatusIcon(
                    icon: Icons.sms, 
                    color: smsColor, 
                    onTap: _sosLogic.smsPermissionOk 
                        ? () => _showSuccessToast(context, l10n.permSmsOk)
                        : () => _showRestrictedPermissionGuide(context, l10n.permSmsMissing),
                  ),
                  // 2. NOTIFICACIONES
                  _buildStatusIcon(
                    icon: Icons.notifications_active, 
                    color: notifColor, 
                    onTap: _sosLogic.notificationPermissionOk 
                        ? () => _showSuccessToast(context, l10n.permNotifOk)
                        : () => _showSimplePermissionDialog(context, l10n.permNotifMissing),
                  ),
                  // 3. CONTACTOS
                  _buildStatusIcon(
                    icon: hasContacts ? Icons.people_alt : Icons.person_off, 
                    color: contactColor, 
                    onTap: hasContacts 
                        ? () => _showSuccessToast(context, "${l10n.settingsLabel} OK")
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.errorNoContact, style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.orange
                              )
                            );
                            _sosLogic.openSettings(context);
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

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

            // DASHBOARD INFERIOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Fuerza G
                  GestureDetector(
                    onTap: !_sosLogic.sensorsPermissionOk ? () {
                      _showSensorErrorDialog(context, l10n);
                    } : null,
                    child: Column(
                      children: [
                        Icon(gForceIcon, color: gForceColor, size: 48),
                        const SizedBox(height: 6),
                        Text(
                          gForceText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ],
                    ),
                  ),

                  // Batería
                  GestureDetector(
                    onTap: !_sosLogic.batteryOptimizationOk ? () {
                       _showBatteryDialog(context, l10n);
                    } : null,
                    child: Column(
                      children: [
                        Icon(battIcon, color: battColor, size: 48),
                        const SizedBox(height: 6),
                        Text(
                          "${_sosLogic.batteryLevel}%", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ],
                    ),
                  ),

                  // GPS
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
            
            // 🟢 RESTAURADO: Banner de Modo Test
            if (_sosLogic.currentInactivityLimit < 60) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade800),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        // Usamos fallback por seguridad
                        l10n.testModeWarning, 
                        style: TextStyle(
                          color: Colors.orange.shade900, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 13
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 30),

            // INTERRUPTORES
            _buildQuickToggle(
              context, 
              l10n.autoModeLabel, 
              _sosLogic.isFallDetectionActive, 
              (v) {
                if (v && !_sosLogic.smsPermissionOk) {
                   _showSmsRequiredError(context, l10n);
                   return; 
                }
                _sosLogic.toggleFallDetection(v);
                if (v && !_hasShownWarning) {
                   _showKeepAliveWarning(context, l10n);
                   _hasShownWarning = true;
                }
              },
              Icons.health_and_safety 
            ),
            _buildQuickToggle(
              context, 
              l10n.inactivityModeLabel, 
              _sosLogic.isInactivityMonitorActive, 
              (v) {
                if (v && !_sosLogic.smsPermissionOk) {
                   _showSmsRequiredError(context, l10n);
                   return;
                }
                _sosLogic.toggleInactivityMonitor(v);
                if (v && !_hasShownWarning) {
                   _showKeepAliveWarning(context, l10n);
                   _hasShownWarning = true;
                }
              },
              Icons.airline_seat_flat, 
              // 🟢 ARREGLADO: Subtítulo con valor real
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
            final l10n = AppLocalizations.of(context)!;

            bool smsGranted = await Permission.sms.isGranted;
            if (!smsGranted) {
               _showErrorSnackBar(context, l10n.permSmsMissing, 
                  actionLabel: l10n.menuSettings.toUpperCase(),
                  onAction: () => _showRestrictedPermissionGuide(context, l10n.permSmsMissing)
               );
               return; 
            }

            bool locGranted = await Permission.location.isGranted;
            if (!locGranted) {
               _showErrorSnackBar(context, l10n.permLocMissing, 
                  actionLabel: l10n.btnGoToSettings.toUpperCase(),
                  onAction: () => openAppSettings()
               );
               return; 
            }

            bool restricted = await _sosLogic.arePermissionsRestricted();
            if (restricted) {
               if (mounted) _showRestrictedPermissionGuide(context, l10n.permDialogTitle);
               return; 
            }
          }
          onChanged(newValue);
        },
        activeColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildStatusIcon({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  void _showRestrictedPermissionGuide(BuildContext context, String introText) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogPermissionTitle), 
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(introText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            Text(l10n.dialogPermissionStep1),
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep2, style: const TextStyle(fontWeight: FontWeight.bold)), 
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep3),
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            child: Text(l10n.btnGoToSettings),
          ),
        ],
      ),
    );
  }

  void _showSimplePermissionDialog(BuildContext context, String reason) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.notifications_off, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text(l10n.permDialogTitle))]),
        content: Text(reason), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")), ElevatedButton(onPressed: () { Navigator.pop(ctx); openAppSettings(); }, child: Text(l10n.btnGoToSettings))]
      ));
  }

  void _showSensorErrorDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.run_circle, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text(l10n.permDialogTitle))]),
        content: Text(l10n.permSensorsMissing), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")), ElevatedButton(onPressed: () { Navigator.pop(ctx); openAppSettings(); }, child: Text(l10n.btnGoToSettings))]
      ));
  }

  void _showBatteryDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.battery_alert, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text(l10n.batteryDialogTitle))]),
        content: Text(l10n.batteryDialogBody), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")), ElevatedButton(onPressed: () { Navigator.pop(ctx); _sosLogic.requestBatteryOptimizationIgnore(); }, child: Text(l10n.btnDisableBatterySaver))]
      ));
  }

  void _showSuccessToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]),
        backgroundColor: Colors.green[700], behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  void _showSmsRequiredError(BuildContext context, AppLocalizations l10n) {
    _triggerErrorHaptic();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.permSmsMissing, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red[800], behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: l10n.menuSettings.toUpperCase(), textColor: Colors.white, onPressed: () => _showRestrictedPermissionGuide(context, l10n.permSmsMissing))));
  }

  void _showErrorSnackBar(BuildContext context, String msg, {required String actionLabel, required VoidCallback onAction}) {
    _triggerErrorHaptic();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis))]), 
        backgroundColor: Colors.red[800], behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)));
  }

  void _showKeepAliveWarning(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.warningKeepAlive, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[900], behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16), duration: const Duration(seconds: 6),
        action: SnackBarAction(label: "OK", textColor: Colors.white, onPressed: () { ScaffoldMessenger.of(context).clearSnackBars(); })));
  }
}