import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      
      // CONFIGURACIÓN DE IDIOMAS
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // Inglés
        Locale('es'), // Español
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

  Future<void> _activarProtocoloSOS() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isLoading = true;
      _customStatusMessage = l10n.statusConnecting;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Sin permiso GPS';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String mapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String mensaje = l10n.panicMessage(mapsLink);

      final Uri whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensaje)}");

      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Error launching WhatsApp';
      }

      setState(() {
        _isLoading = false;
        _customStatusMessage = l10n.statusSent;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _customStatusMessage = l10n.statusError(e.toString());
      });
    }
  }

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
      
      // BARRA SUPERIOR
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      // MENÚ LATERAL COMPLETO
      drawer: Drawer(
        backgroundColor: const Color(0xFF181818),
        child: Column(
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
                      l10n.motto, // Usa el texto con el ; del archivo de idioma
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            // 1. SELECTOR DE IDIOMA
            ExpansionTile(
              leading: const Icon(Icons.translate, color: Colors.orangeAccent),
              title: Text(l10n.menuLanguages, style: const TextStyle(color: Colors.white)),
              children: [
                ListTile(
                  title: const Text("Español", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    widget.onLanguageChanged(const Locale('es'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text("English", style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    widget.onLanguageChanged(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            const Divider(color: Colors.white10),

            // 2. REDES SOCIALES Y WEB (Recuperados)
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blueAccent),
              title: Text(l10n.menuWeb, style: const TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://oksigenia.com'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purpleAccent),
              title: const Text('Instagram', style: TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://instagram.com/oksigenia'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white),
              title: const Text('X (Twitter)', style: TextStyle(color: Colors.white)),
              onTap: () => _abrirLink('https://x.com/oksigeniaX'),
            ),
            
            const Divider(color: Colors.white10),
            
            // 3. SOPORTE (Recuperado)
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.greenAccent),
              title: Text(l10n.menuSupport, style: const TextStyle(color: Colors.white)),
              subtitle: const Text('contacto@oksigenia.com', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: _enviarEmail,
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("© 2026 Oksigenia v0.4", style: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
      ),
      
      // BOTÓN SOS
      body: Center(
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
                      : Text(l10n.sosButton, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _customStatusMessage ?? l10n.statusReady,
                style: const TextStyle(color: Colors.white70, fontFamily: 'Monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}