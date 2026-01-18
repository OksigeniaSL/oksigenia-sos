import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Importaciones modulares
import 'package:oksigenia_sos/logic/sos_logic.dart'; 
import 'package:oksigenia_sos/screens/disclaimer_screen.dart';
import 'package:oksigenia_sos/services/preferences_service.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/services/background_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializamos el servicio
  await initializeService();
  
  // 2. Inicializamos preferencias
  await PreferencesService().init(); 
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    OksigeniaApp(
      initialAccepted: prefs.getBool('disclaimer_accepted') ?? false
    )
  );
}

class OksigeniaApp extends StatefulWidget {
  final bool initialAccepted;
  const OksigeniaApp({super.key, required this.initialAccepted});

  @override
  State<OksigeniaApp> createState() => _OksigeniaAppState();
}

class _OksigeniaAppState extends State<OksigeniaApp> {
  Locale? _locale;
  void setLocale(Locale l) => setState(() { _locale = l; });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oksigenia SOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), 
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100]
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate, 
        GlobalMaterialLocalizations.delegate, 
        GlobalWidgetsLocalizations.delegate, 
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('en'), Locale('es'), Locale('fr'), Locale('pt'), Locale('de')
      ],
      locale: _locale,
      home: widget.initialAccepted ? const HomeScreen() : const DisclaimerScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SOSLogic _sosLogic = SOSLogic(); 
  bool _isInitLocked = false;

  @override
  void initState() {
    super.initState();
    _sosLogic.init();
    _sosLogic.addListener(() { if (mounted) setState(() {}); });
    WakelockPlus.enable(); 
    
    // Arranque diferido
    Timer(const Duration(seconds: 10), () => _initEmergencySystem());
  }

  Future<void> _initEmergencySystem() async {
    if (_isInitLocked) return;
    _isInitLocked = true;
    try {
      var nStatus = await Permission.notification.request();
      await Future.delayed(const Duration(seconds: 3));
      var lStatus = await Permission.location.request();

      if (nStatus.isGranted && lStatus.isGranted) {
        final service = FlutterBackgroundService();
        if (!await service.isRunning()) {
          await service.startService();
          await Future.delayed(const Duration(seconds: 5));
          service.invoke('forceForegroundNow');
        }
      }
    } catch (e) {
      debugPrint("Error arranque: $e");
    } finally {
      if (mounted) setState(() { _isInitLocked = false; });
    }
  }

  void _showRestrictedGuide(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.security, color: Colors.orange), const SizedBox(width: 10), Text(l10n.restrictedSettingsTitle)]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restrictedSettingsBody),
            const SizedBox(height: 15),
            const Text("1. Ajustes > Aplicaciones > Oksigenia SOS", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("2. Toca (⋮) > 'Permitir ajustes restringidos'", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.btnClose)),
          ElevatedButton(onPressed: () => openAppSettings(), child: Text(l10n.btnGoToSettings)),
        ],
      ),
    );
  }

  @override
  void dispose() { _sosLogic.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_sosLogic.status == SOSStatus.preAlert) return _buildPreAlertOverlay(l10n);
    if (_sosLogic.status == SOSStatus.sent) return _buildSentOverlay(l10n);

    return Scaffold(
      appBar: AppBar(
        title: const Text("OKSIGENIA SOS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(v, l10n),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'settings', child: _menuItem(Icons.phone, l10n.menuSettings)),
              PopupMenuItem(value: 'privacy', child: _menuItem(Icons.security, l10n.menuPrivacy)),
              PopupMenuItem(value: 'languages', child: _menuItem(Icons.language, l10n.menuLanguages)),
              PopupMenuItem(value: 'donate', child: _menuItem(Icons.favorite, l10n.menuDonate)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'web', child: _menuItem(Icons.public, l10n.menuWeb)),
              PopupMenuItem(value: 'x', child: _menuItem(Icons.close, l10n.menuX)),
              PopupMenuItem(value: 'insta', child: _menuItem(Icons.camera_alt, l10n.menuInsta)),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_sosLogic.currentInactivityLimit == 30) _testModeBanner(l10n),
              _buildStatusBadge(l10n),
              const SizedBox(height: 40), 
              _buildSOSButton(l10n),
              const SizedBox(height: 40),
              _buildGForceIndicator(),
              const SizedBox(height: 30),
              _buildFeatureCard(Icons.bolt, l10n.autoModeLabel, _sosLogic.isFallDetectionActive, (v) => _sosLogic.toggleFallDetection(v), l10n),
              _buildFeatureCard(Icons.timer, l10n.inactivityModeLabel, _sosLogic.isInactivityMonitorActive, (v) => _sosLogic.toggleInactivityMonitor(v), l10n),
              const SizedBox(height: 30),
              const Text("Respira > Inspira > Crece;", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testModeBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.orange)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.warning, color: Colors.orange, size: 20), const SizedBox(width: 8), Flexible(child: Text(l10n.testModeWarning, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center))]),
    );
  }

  void _handleMenu(String v, AppLocalizations l10n) {
    if (v == 'settings') _sosLogic.openSettings(context);
    if (v == 'privacy') _sosLogic.openPrivacy(context);
    if (v == 'languages') _showLanguageDialog(context); 
    if (v == 'donate') _sosLogic.openDonation(context);
    if (v == 'web') _sosLogic.launchURL("https://oksigenia.com");
    if (v == 'x') _sosLogic.launchURL("https://x.com/oksigeniaX");
    if (v == 'insta') _sosLogic.launchURL("https://instagram.com/oksigenia");
  }

  Widget _menuItem(IconData icon, String text) => Row(children: [Icon(icon, color: Colors.grey[700], size: 20), const SizedBox(width: 12), Text(text)]);

  Widget _buildStatusBadge(AppLocalizations l10n) {
    Color c = Colors.orange; 
    String text = l10n.statusReady; 
    if (_sosLogic.status == SOSStatus.locationFixed) { c = Colors.green; text = l10n.statusLocationFixed; }
    else if (_sosLogic.status == SOSStatus.scanning) { c = Colors.blue; text = l10n.statusConnecting; }
    else if (_sosLogic.status == SOSStatus.error) { c = Colors.red; text = "GPS ERROR"; } 
    else if (_sosLogic.isFallDetectionActive || _sosLogic.isInactivityMonitorActive) { c = Colors.cyan.shade700; text = "MONITORIZANDO"; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: c)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, color: c, size: 10), const SizedBox(width: 8), Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildGForceIndicator() => Column(children: [const Text("FORCE G", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), Text("${_sosLogic.currentGForce.toStringAsFixed(2)} G", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _sosLogic.currentGForce > 3.0 ? Colors.red : Colors.grey[600]))]);

  Widget _buildSOSButton(AppLocalizations l10n) => GestureDetector(
      onLongPress: () => _sosLogic.sendSOS(),
      onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toastHoldToSOS), duration: const Duration(seconds: 1))); },
      child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)]), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 30, spreadRadius: 10)]), child: Center(child: Text(l10n.sosButton, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)))),
    );

  Widget _buildFeatureCard(IconData i, String t, bool v, Function(bool) onChanged, AppLocalizations l10n) => Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)), color: Colors.white,
      child: SwitchListTile(
        secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(i, color: Colors.grey[800])),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        value: v, activeColor: Colors.red,
        onChanged: (val) async {
           if (val && (_sosLogic.emergencyContact == null)) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorNoContact), backgroundColor: Colors.red, action: SnackBarAction(label: "CONFIG", textColor: Colors.white, onPressed: () => _sosLogic.openSettings(context))));
             return;
           }
           if (val) {
             var smsStatus = await Permission.sms.status;
             if (!smsStatus.isGranted) { _showRestrictedGuide(l10n); return; }
           }
           onChanged(val);
        },
      ),
    );

  Widget _buildPreAlertOverlay(AppLocalizations l10n) {
    String title = _sosLogic.lastTrigger == AlertCause.fall ? l10n.alertFallDetected : l10n.alertInactivityDetected;
    String body = _sosLogic.lastTrigger == AlertCause.fall ? l10n.alertFallBody : l10n.alertInactivityBody;
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 100),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const Spacer(),
        Stack(alignment: Alignment.center, children: [SizedBox(width: 200, height: 200, child: CircularProgressIndicator(value: _sosLogic.countdownSeconds / 60, strokeWidth: 15, color: Colors.white, backgroundColor: Colors.white24)), Text("${_sosLogic.countdownSeconds}", style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold))]),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(30.0), child: SizedBox(width: double.infinity, height: 70, child: ElevatedButton(onPressed: () => _sosLogic.cancelAlert(), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red[900]), child: Text(l10n.btnImOkay, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))))),
      ])),
    );
  }
  
  Widget _buildSentOverlay(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.blue[800], 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                child: const Icon(Icons.check, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 40),
              Text(l10n.statusSent, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Tus contactos han sido notificados.\nAyuda en camino.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 18)),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(onPressed: () => _sosLogic.cancelAlert(), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue[900], elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("REINICIAR SISTEMA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => SimpleDialog(title: const Text('Idioma / Language'), children: [_langOption('Español', const Locale('es')), _langOption('English', const Locale('en')), _langOption('Français', const Locale('fr')), _langOption('Português', const Locale('pt')), _langOption('Deutsch', const Locale('de'))]));
  }

  Widget _langOption(String text, Locale locale) {
    return SimpleDialogOption(
      onPressed: () async {
        // 1. Guardar en disco
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', locale.languageCode);
        
        // 2. Ordenar a Sylvia que cambie el idioma YA
        final service = FlutterBackgroundService();
        service.invoke('updateLanguage');

        // 3. Actualizar la UI
        if (context.mounted) {
          context.findAncestorStateOfType<_OksigeniaAppState>()?.setLocale(locale); 
          Navigator.pop(context); 
        }
      },
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(text, style: const TextStyle(fontSize: 16))),
    );
  }
}