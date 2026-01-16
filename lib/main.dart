import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const OksigeniaSOSApp());
}

class OksigeniaSOSApp extends StatelessWidget {
  const OksigeniaSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Sin etiqueta de Debug
      title: 'Oksigenia SOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C), // Rojo Corporativo
          brightness: Brightness.dark, // Modo oscuro
          primary: const Color(0xFFD32F2F),
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      home: const SOSScreen(),
    );
  }
}

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _isLoading = false;
  String _statusMessage = "Sistema Oksigenia listo.";

  // --- LÓGICA DEL BOTÓN DE PÁNICO ---
  Future<void> _activarProtocoloSOS() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Conectando satélites...";
    });

    try {
      // 1. Permisos GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Sin permiso GPS';
      }

      // 2. Obtener Posición Exacta
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Crear enlace y mensaje
      String mapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String mensaje = "🆘 *ALERTA OKSIGENIA* 🆘\n\n"
          "Necesito ayuda urgente.\n"
          "📍 Ubicación: $mapsLink\n\n"
          "Respira > Inspira > Crece";

      // 4. Lanzar WhatsApp
      final Uri whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensaje)}");

      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Error al abrir WhatsApp';
      }

      setState(() {
        _isLoading = false;
        _statusMessage = "Alerta enviada correctamente.";
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "ERROR: $e";
      });
    }
  }

  // --- LÓGICA PARA ABRIR WEBS Y CORREO ---
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
    return Scaffold(
      backgroundColor: Colors.black,

      // --- BARRA SUPERIOR ---
      appBar: AppBar(
        title: const Text(
          "OKSIGENIA S.O.S",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // --- MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        backgroundColor: const Color(0xFF181818),
        child: Column(
          children: [
            // Cabecera con Logo
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
                    // LOGO (Con filtro blanco para contraste)
                    Image.asset(
                      'assets/images/OksigeniaAlfa.png',
                      height: 80,
                      color: Colors.white, // <--- ESTO LO HACE BLANCO
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Respira > Inspira > Crece",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones del Menú
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blueAccent),
              title: const Text('Web Oficial', style: TextStyle(color: Colors.white)),
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.white24),
            ),

            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.greenAccent),
              title: const Text('Soporte Técnico', style: TextStyle(color: Colors.white)),
              subtitle: const Text('contacto@oksigenia.com', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: _enviarEmail,
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "© 2026 Oksigenia v0.3",
                style: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),

      // --- CUERPO (BOTÓN SOS) ---
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
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(
                        color: const Color(0xFFB71C1C).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                  ],
                  border: Border.all(color: Colors.white12, width: 3),
                ),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SOS",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}