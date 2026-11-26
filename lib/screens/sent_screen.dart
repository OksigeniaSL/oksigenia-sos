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
    // How the SOS really went (contacts reached, retries, beacon): both
    // isolates leave it in prefs, so it is also right when Sylvia sent it with
    // the UI closed.
    context.read<SOSLogic>().refreshSentSummary();
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

    // "Sent" only when every contact has it. With 1 of 3 the title says so,
    // in amber, and the line below says the rest is being retried.
    final bool everyone = logic.sentToEveryone;
    final Color accent = everyone ? Colors.greenAccent : Colors.amberAccent;
    final String title = everyone
        ? l10n.statusSent
        : l10n.sentPartialTitle('${logic.sentCount}', '${logic.sentTotal}');
    final List<String> notes = [
      if (logic.retryPendingCount > 0) l10n.statusSendRetrying,
      if (logic.beaconActive) l10n.sentBeaconInfo,
      l10n.statusScreenSleep,
    ];

    final mq = MediaQuery.of(context);
    // Short screens (360×640 and similar) get tighter spacing, and the system
    // font scale is capped here as on the alarm screen: at 200 % the button
    // and its explanation alone filled the screen.
    final bool compact = mq.size.height < 700;
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo Oscuro (Modo Táctico)
      body: PopScope(
        canPop: false, // Bloqueamos el botón atrás físico
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(compact ? 20 : 30),
            child: Column(
              children: [
                // What happened. It scrolls when it does not fit (large text
                // on a short screen), so the button below is never pushed out.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accent, width: 4),
                            ),
                            padding: EdgeInsets.all(compact ? 14 : 25),
                            child: Icon(Icons.check, size: compact ? 40 : 60, color: accent),
                          ),
                          SizedBox(height: compact ? 16 : 40),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 20),
                          for (final String note in notes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                note,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // What the button does, in plain words: it used to read
                // "RESTART SYSTEM" and nothing said it ends the follow-ups.
                Text(
                  l10n.sentStopExplain,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // resetSystem (no cancelAlert): apaga el beacon y vacía la
                    // cola de reintentos. cancelAlert dejaba el beacon vivo
                    // enviando avisos de movimiento sin parada posible (bug de
                    // campo 2026-06-13).
                    onPressed: () => logic.resetSystem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(60),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    child: Text(
                      l10n.btnSafeStop,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 20),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
