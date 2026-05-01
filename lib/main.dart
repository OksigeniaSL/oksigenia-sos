import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/services/preferences_service.dart';
import 'package:oksigenia_sos/services/background_service.dart'; 
import 'package:oksigenia_sos/screens/disclaimer_screen.dart';
import 'package:oksigenia_sos/screens/home_screen.dart';
import 'package:oksigenia_sos/screens/onboarding_screen.dart';
import 'package:oksigenia_sos/logic/sos_logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 BLOQUEO DE ROTACIÓN
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // 1. INICIALIZACIÓN BÁSICA
  await PreferencesService().init(); 
  final prefs = await SharedPreferences.getInstance();

  // 2. DESPERTAR A SYLVIA
  await initializeService(); 
  
  final bool accepted = prefs.getBool('disclaimer_accepted') ?? false;
  final bool onboardingDone = prefs.getBool('onboarding_completed') ?? false;
  final String? savedLang = prefs.getString('language_code');

  // 3. INICIALIZAR EL CEREBRO (Lógica SOS)
  final sosLogic = SOSLogic();

  // Only init if both disclaimer accepted and onboarding completed.
  // New users pass through DisclaimerScreen → OnboardingScreen → HomeScreen,
  // which triggers init() via HomeScreen.initState().
  if (accepted && onboardingDone) {
    await sosLogic.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sosLogic),
      ],
      child: OksigeniaApp(
        initialAccepted: accepted,
        onboardingDone: onboardingDone,
        savedLanguage: savedLang,
      ),
    ),
  );
}

class OksigeniaApp extends StatefulWidget {
  final bool initialAccepted;
  final bool onboardingDone;
  final String? savedLanguage;

  const OksigeniaApp({
    super.key,
    required this.initialAccepted,
    required this.onboardingDone,
    this.savedLanguage,
  });

  @override
  State<OksigeniaApp> createState() => _OksigeniaAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _OksigeniaAppState? state = context.findAncestorStateOfType<_OksigeniaAppState>();
    state?.setLocale(newLocale);
  }
}

class _OksigeniaAppState extends State<OksigeniaApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.savedLanguage != null) {
      _locale = Locale(widget.savedLanguage!);
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. OBLIGAMOS AL SISTEMA (Barras de estado y navegación) A SER OSCUROS
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Iconos blancos (sobre fondo oscuro)
      systemNavigationBarColor: Colors.black,    // Barra de abajo NEGRA (Adiós flashazo)
      systemNavigationBarIconBrightness: Brightness.light, // Botones blancos
    ));

    return MaterialApp(
      navigatorKey: oksigeniaNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Oksigenia SOS',
      
      // 2. LA DICTADURA: Ignoramos la configuración del usuario
      themeMode: ThemeMode.dark, 

      // 3. TRAMPA: Definimos el tema "Light" TAMBIÉN como oscuro
      // (Por si acaso Flutter intenta cargar el light por error milisegundos antes)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C), 
          brightness: Brightness.dark, // Forzado dark
        ),
        useMaterial3: true,
      ),

      // 4. EL TEMA OSCURO REAL
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Negro absoluto
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C), 
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // Idiomas (Esto lo dejamos igual)
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('pt'),
        Locale('nl'),
        Locale('sv'),
        Locale('it'),
        Locale('pl'),
        Locale('ru'),
        Locale('nb'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      home: widget.initialAccepted
          ? (widget.onboardingDone ? const HomeScreen() : const OnboardingScreen())
          : const DisclaimerScreen(),
    );
  }
}