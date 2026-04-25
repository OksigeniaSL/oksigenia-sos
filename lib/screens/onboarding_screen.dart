import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _platform = MethodChannel('com.oksigenia.sos/sms');

  bool _smsDone = false;
  bool _locDone = false;
  bool _notifDone = false;
  bool _activityDone = false;
  bool _batteryDone = false;
  bool _fullScreenDone = false;
  bool _refreshing = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final sms = await Permission.sms.isGranted;
    final loc = await Permission.location.isGranted;
    final notif = await Permission.notification.isGranted;
    final activity = await Permission.activityRecognition.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    bool fs = true;
    try {
      fs = await _platform.invokeMethod('canUseFullScreenIntent') ?? true;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _smsDone = sms;
      _locDone = loc;
      _notifDone = notif;
      _activityDone = activity;
      _batteryDone = battery;
      _fullScreenDone = fs;
      _refreshing = false;
    });
  }

  bool get _mandatoryDone => _smsDone && _locDone && _notifDone && _activityDone && _batteryDone;

  Future<void> _grantSms() async {
    await Permission.sms.request();
    await _refresh();
  }

  Future<void> _grantLocation() async {
    await [Permission.location, Permission.locationWhenInUse].request();
    await _refresh();
  }

  Future<void> _grantNotification() async {
    await Permission.notification.request();
    await _refresh();
  }

  Future<void> _grantActivity() async {
    await Permission.activityRecognition.request();
    await _refresh();
  }

  Future<void> _grantBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refresh();
  }

  Future<void> _grantFullScreen() async {
    try {
      await _platform.invokeMethod('requestFullScreenIntentPermission');
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (_) {}
    await _refresh();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Image.asset('assets/images/logo_oksigenia.png', width: 36, height: 36,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Colors.amber, size: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.onboardingTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _refreshing
                    ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                    : ListView(
                        children: [
                          _PermRow(
                            icon: Icons.message_outlined,
                            title: "SMS",
                            subtitle: l10n.permSmsOk,
                            mandatory: true,
                            granted: _smsDone,
                            l10n: l10n,
                            onGrant: _grantSms,
                          ),
                          _PermRow(
                            icon: Icons.location_on_outlined,
                            title: "GPS / Location",
                            subtitle: l10n.gpsHelpTitle,
                            mandatory: true,
                            granted: _locDone,
                            l10n: l10n,
                            onGrant: _grantLocation,
                          ),
                          _PermRow(
                            icon: Icons.notifications_outlined,
                            title: "Notifications",
                            subtitle: l10n.permNotifOk,
                            mandatory: true,
                            granted: _notifDone,
                            l10n: l10n,
                            onGrant: _grantNotification,
                          ),
                          _PermRow(
                            icon: Icons.directions_run,
                            title: "Activity / Sensors",
                            subtitle: l10n.autoModeDescription,
                            mandatory: true,
                            granted: _activityDone,
                            l10n: l10n,
                            onGrant: _grantActivity,
                          ),
                          _PermRow(
                            icon: Icons.battery_charging_full,
                            title: l10n.batteryDialogTitle,
                            subtitle: l10n.batteryDialogBody,
                            mandatory: true,
                            granted: _batteryDone,
                            l10n: l10n,
                            onGrant: _grantBattery,
                          ),
                          _PermRow(
                            icon: Icons.lock_open_outlined,
                            title: l10n.fullScreenIntentTitle,
                            subtitle: l10n.fullScreenIntentBody,
                            mandatory: false,
                            granted: _fullScreenDone,
                            l10n: l10n,
                            onGrant: _grantFullScreen,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _mandatoryDone ? _finish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[850],
                    disabledForegroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    l10n.onboardingFinish,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool mandatory;
  final bool granted;
  final AppLocalizations l10n;
  final VoidCallback onGrant;

  const _PermRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mandatory,
    required this.granted,
    required this.l10n,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: granted ? Colors.green.withOpacity(0.5) : Colors.grey[800]!,
          width: granted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: granted ? Colors.green : Colors.grey[400], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (!mandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        ),
                      ),
                    if (mandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.onboardingMandatory,
                          style: const TextStyle(color: Colors.red, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          granted
              ? Text(
                  l10n.onboardingGranted,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                )
              : SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onGrant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    child: Text(l10n.onboardingGrant),
                  ),
                ),
        ],
      ),
    );
  }
}
