import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORTANTE: Persistencia
import 'l10n/app_localizations.dart';

void main() {
  runApp(const OksigeniaSOSApp());
}

class OksigeniaSOSApp extends StatefulWidget {
  const OksigeniaSOSApp({super.key});

  @override
  State<OksigeniaSOSApp> createState() => _OksigeniaSOSAppState();
}

class _OksigeniaSOSAppState extends State<OksigeniaSOSApp> {
  Locale? _locale;

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oksigenia SOS',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), 
        Locale('es'), 
        Locale('fr'), 
        Locale('pt'), 
        Locale('de'), 
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
          primary: const Color(0xFFD32F2F),
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      home: SOSScreen(onLanguageChanged: _changeLanguage),
    );
  }
}

class SOSScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  
  const SOSScreen({super.key, required this.onLanguageChanged});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isLoading = false;
  String? _customStatusMessage;

  // Lógica de Activación SOS
  Future<void> _activarProtocoloSOS() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. RECUPERAR NÚMERO GUARDADO
    final prefs = await SharedPreferences.getInstance();
    final String? contactoEmergencia = prefs.getString('sos_contact');

    // Validación: Si no hay contacto, mandamos al usuario a Configuración
    if (contactoEmergencia == null || contactoEmergencia.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorNoContact),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        // Navegar a Configuración automáticamente
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigScreen()),
        );
      }
      return; // Detener ejecución
    }

    setState(() {
      _isLoading = true;
      _customStatusMessage = l10n.statusConnecting;
    });

    String mensajeFinal = "";
    String ubicacionUrl = "";

    // --- FASE 1: GEOLOCALIZACIÓN ---
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS_OFF';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'GPS_DENIED';
      }
      
      if (permission == LocationPermission.deniedForever) throw 'GPS_BLOCKED';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), 
      );

      ubicacionUrl = "http://maps.google.com/?q=${position.latitude},${position.longitude}";
      mensajeFinal = l10n.panicMessage(ubicacionUrl);

    } catch (e) {
      debugPrint("⚠️ Fallo GPS Controlado: $e");
      mensajeFinal = l10n.panicMessage("N/A (GPS Error/Timeout)");
    }

    // --- FASE 2: ENVÍO SMS ---
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: contactoEmergencia, // Usamos el número recuperado de memoria
        queryParameters: <String, String>{
          'body': mensajeFinal,
        },
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.platformDefault);
        
        setState(() {
          _isLoading = false;
          _customStatusMessage = l10n.statusSent;
        });
      } else {
        throw 'NO_SMS_APP';
      }

    } catch (e) {
      debugPrint("❌ Error SMS: $e");
      setState(() {
        _isLoading = false;
        _customStatusMessage = l10n.statusError("SMS ERROR");
      });
    }
  }

  // --- NAVEGACIÓN ---
  Future<void> _abrirLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Error abriendo $url");
    }
  }

  Future<void> _enviarEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contacto@oksigenia.com',
      query: 'subject=Soporte App Oksigenia&body=Hola equipo...',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint("Error abriendo correo");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const CircularProgressIndicator();

    return Scaffold(
      backgroundColor: Colors.black,
      
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      drawer: Drawer(
        backgroundColor: const Color(0xFF181818),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F1F1F), Color(0xFF000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/OksigeniaAlfa.png', height: 80, color: Colors.white),
                    const SizedBox(height: 15),
                    Text(
                      l10n.motto,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            // BOTÓN DE CONFIGURACIÓN (NUEVO)
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.redAccent),
              title: Text(l10n.menuSettings, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Cierra drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigScreen()));
              },
            ),
            
            const Divider(color: Colors.white10),

            ExpansionTile(
              leading: const Icon(Icons.translate, color: Colors.orangeAccent),
              title: Text(l10n.menuLanguages, style: const TextStyle(color: Colors.white)),
              children: [
                _buildLanguageItem(context, "ES", "Español", const Locale('es')),
                _buildLanguageItem(context, "EN", "English", const Locale('en')),
                _buildLanguageItem(context, "FR", "Français", const Locale('fr')),
                _buildLanguageItem(context, "PT", "Português", const Locale('pt')),
                _buildLanguageItem(context, "DE", "Deutsch", const Locale('de')),
              ],
            ),

            const Divider(color: Colors.white10),

            ListTile(
              leading: const FaIcon(FontAwesomeIcons.globe, color: Colors.blueAccent),
              title: Text(l10n.menuWeb, style: const TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://oksigenia.com'),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.instagram, color: Colors.purpleAccent),
              title: const Text('Instagram', style: TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://instagram.com/oksigenia'),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.xTwitter, color: Colors.white),
              title: const Text('X', style: TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://x.com/oksigeniaX'),
            ),
            
            const Divider(color: Colors.white10),
            
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.greenAccent),
              title: Text(l10n.menuSupport, style: const TextStyle(color: Colors.white)),
              subtitle: const Text('contacto@oksigenia.com', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: _enviarEmail,
            ),

            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("© 2026 Oksigenia v0.9", 
                style: TextStyle(color: Colors.white24),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _activarProtocoloSOS,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isLoading 
                        ? [Colors.grey.shade800, Colors.grey.shade900]
                        : [const Color(0xFFE53935), const Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [if (!_isLoading) BoxShadow(color: const Color(0xFFB71C1C).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                    border: Border.all(color: Colors.white12, width: 3),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            l10n.sosButton, 
                            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _customStatusMessage ?? l10n.statusReady,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontFamily: 'Monospace', 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String code, String label, Locale locale) {
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Center(
          child: Text(
            code,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: () {
        widget.onLanguageChanged(locale);
        Navigator.pop(context);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PANTALLA DE CONFIGURACIÓN (NUEVA CLASE)
// ---------------------------------------------------------------------------
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedNumber();
  }

  Future<void> _loadSavedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneController.text = prefs.getString('sos_contact') ?? '';
    });
  }

  Future<void> _saveNumber() async {
    setState(() { _isSaving = true; });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_contact', _phoneController.text.trim());
    
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSavedMsg), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Volver atrás al guardar
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha atrás blanca
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: l10n.settingsHint,
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone, color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.settingsSave, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}