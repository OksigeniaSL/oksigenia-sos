import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oksigenia_sos/logic/sos_logic.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';

class SentScreen extends StatefulWidget {
  const SentScreen({super.key});

  @override
  State<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends State<SentScreen> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // Autocierre en 15 segundos para ahorrar batería si el usuario no toca nada
    _autoCloseTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        context.read<SOSLogic>().cancelAlert(); // Esto resetea todo limpiamente
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logic = context.watch<SOSLogic>();

    // Si la lógica dice que ya no estamos en "enviado" (ej: se canceló), cerramos
    if (logic.status != SOSStatus.sent) {
      // Usamos un post-frame callback para evitar errores de renderizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo Oscuro (Modo Táctico)
      body: PopScope(
        canPop: false, // Bloqueamos el botón atrás físico
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Círculo de Éxito
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 4),
                  ),
                  padding: const EdgeInsets.all(25),
                  child: const Icon(Icons.check, size: 60, color: Colors.greenAccent),
                ),
                const SizedBox(height: 40),
                
                // Título
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
                
                // Subtítulos informativos (Ya traducidos)
                Text(
                  "${l10n.statusMonitorStopped}\n${l10n.statusScreenSleep}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                
                const Spacer(),
                
                // Botón Gigante de Reinicio
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => logic.cancelAlert(), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ), 
                    child: Text(
                      l10n.btnRestartSystem, // "REINICIAR SISTEMA"
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}