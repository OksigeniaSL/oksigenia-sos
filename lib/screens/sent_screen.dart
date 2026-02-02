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
    // Autocierre en 10 segundos para no bloquear el móvil eternamente
    _autoCloseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        final logic = context.read<SOSLogic>();
        logic.imOkay(); // Vuelve a estado 'ready'
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

    // Si el estado ya no es 'sent', cerramos esta pantalla
    if (logic.status != SOSStatus.sent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: Colors.green[700], // Verde Éxito
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono gigante
              const Icon(Icons.check_circle_outline, size: 120, color: Colors.white),
              const SizedBox(height: 30),
              
              // Textos
              Text(
                l10n.statusSent, // "Alerta enviada"
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "SMS & GPS Coordinates Sent", 
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),

              // Botón "Estoy Bien"
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  logic.imOkay(); // Resetea el sistema
                },
                icon: const Icon(Icons.thumb_up),
                label: Text(
                  l10n.btnImOkay.toUpperCase(), // "ESTOY BIEN"
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}