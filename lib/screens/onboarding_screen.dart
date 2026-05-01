import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import 'package:oksigenia_sos/screens/home_screen.dart';
import 'package:oksigenia_sos/main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.oksigenia.sos/sms');

  bool _smsDone = false;
  bool _locDone = false;
  bool _notifDone = false;
  bool _activityDone = false;
  bool _sensorsDone = false;
  bool _batteryDone = false;
  bool _fullScreenDone = false;
  bool _refreshing = true;
  Timer? _settingsPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _checkSensorsAsync();
  }

  @override
  void dispose() {
    _settingsPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _checkSensorsAsync();
    }
  }

  void _pollAfterSettings() {
    _settingsPollTimer?.cancel();
    int ticks = 0;
    _settingsPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      ticks++;
      await _refresh();
      if (_mandatoryDone || ticks >= 10) _settingsPollTimer?.cancel();
    });
  }

  Future<bool> _isSmsGranted() async {
    try {
      return await _platform.invokeMethod<bool>('isSmsPermissionGranted') ?? false;
    } catch (_) {
      return Permission.sms.isGranted;
    }
  }

  Future<void> _checkSensorsAsync() async {
    if (_sensorsDone) return;
    final ok = await _checkSensors();
    if (mounted) setState(() => _sensorsDone = ok);
  }

  Future<bool> _checkSensors() async {
    final completer = Completer<bool>();
    StreamSubscription? sub;
    final timer = Timer(const Duration(seconds: 2), () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });
    try {
      sub = accelerometerEventStream().listen(
        (event) {
          timer.cancel();
          sub?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (_) {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(false);
        },
      );
    } catch (_) {
      timer.cancel();
      return false;
    }
    return completer.future;
  }

  Future<void> _refresh() async {
    final sms = await _isSmsGranted();
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

  bool get _mandatoryDone =>
      _smsDone && _locDone && _notifDone && _activityDone && _sensorsDone && _batteryDone;

  Future<void> _openSettingsWithDialog(String permissionName) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(permissionName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Settings → Apps → Oksigenia SOS → Permissions → $permissionName',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.alertCancel, style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: Text(l10n.btnGoToSettings),
          ),
        ],
      ),
    );
    if (open == true) {
      await openAppSettings();
      _pollAfterSettings();
    }
  }

  Future<void> _grantSms() async {
    if (await _isSmsGranted()) { await _refresh(); return; }
    // Trigger Android's "App was denied" notice — this is required to unlock the ⋮ menu in settings
    await Permission.sms.request();
    if (await _isSmsGranted()) { await _refresh(); return; }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.restrictedSettingsTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restrictedSettingsBody,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Text('✅ Step 1 done — Android security notice was shown.',
                style: TextStyle(color: Colors.green[300], fontSize: 13)),
            const SizedBox(height: 10),
            Text('2. Open Settings (button below)',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text('3. Tap ⋮ (top right) → "Allow restricted settings" → PIN',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            Text('4. Permissions → SMS → enable',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.alertCancel, style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: Text(l10n.permSmsButton),
          ),
        ],
      ),
    );
    if (open == true) {
      await openAppSettings();
      _pollAfterSettings();
    }
  }

  Future<void> _grantLocation() async {
    if (await Permission.location.isGranted) { await _refresh(); return; }
    final statuses = await [Permission.location, Permission.locationWhenInUse].request();
    if (statuses.values.every((s) => s.isGranted)) { await _refresh(); return; }
    await _openSettingsWithDialog('Location');
  }

  Future<void> _grantNotification() async {
    if (await Permission.notification.isGranted) { await _refresh(); return; }
    final status = await Permission.notification.request();
    if (status.isGranted) { await _refresh(); return; }
    await _openSettingsWithDialog('Notifications');
  }

  Future<void> _grantActivity() async {
    if (await Permission.activityRecognition.isGranted) { await _refresh(); return; }
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) { await _refresh(); return; }
    await _openSettingsWithDialog('Physical activity');
  }

  Future<void> _grantSensors() async {
    if (_sensorsDone) return;
    await _openSettingsWithDialog('Sensors');
    _checkSensorsAsync();
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

  void _showLanguagePicker() {
    final languages = [
      ('English', 'en', '🇬🇧'),
      ('Español', 'es', '🇪🇸'),
      ('Français', 'fr', '🇫🇷'),
      ('Deutsch', 'de', '🇩🇪'),
      ('Português', 'pt', '🇵🇹'),
      ('Italiano', 'it', '🇮🇹'),
      ('Nederlands', 'nl', '🇳🇱'),
      ('Norsk bokmål', 'nb', '🇳🇴'),
      ('Polski', 'pl', '🇵🇱'),
      ('Русский', 'ru', '🇷🇺'),
      ('Svenska', 'sv', '🇸🇪'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Colors.grey[900],
        title: Text(AppLocalizations.of(context)!.selectLanguage,
            style: const TextStyle(color: Colors.white)),
        children: languages.map((lang) => SimpleDialogOption(
          onPressed: () async {
            Navigator.pop(ctx);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('language_code', lang.$2);
            if (mounted) OksigeniaApp.setLocale(context, Locale(lang.$2));
          },
          child: Row(children: [
            Text(lang.$3, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(lang.$1, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ]),
        )).toList(),
      ),
    );
  }

  void _showWhyPermissions() {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.message_outlined, 'SMS', l10n.whyPermsSms),
      (Icons.location_on_outlined, 'GPS', l10n.whyPermsLocation),
      (Icons.notifications_outlined, 'Notifications', l10n.whyPermsNotifications),
      (Icons.directions_run, 'Physical Activity', l10n.whyPermsActivity),
      (Icons.sensors, 'Motion Sensors', l10n.whyPermsSensors),
      (Icons.battery_charging_full, 'Battery', l10n.whyPermsBattery),
      (Icons.lock_open_outlined, 'Full Screen', l10n.whyPermsFullScreen),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l10n.whyPermsTitle,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            const SizedBox(height: 4),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(items[i].$1, color: Colors.amber, size: 26),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].$2,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(items[i].$3,
                              style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  IconButton(
                    icon: const Icon(Icons.language, color: Colors.white70, size: 22),
                    tooltip: l10n.selectLanguage,
                    onPressed: _showLanguagePicker,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                            mandatory: true,
                            granted: _smsDone,
                            l10n: l10n,
                            onGrant: _grantSms,
                          ),
                          _PermRow(
                            icon: Icons.location_on_outlined,
                            title: "GPS / Location",
                            mandatory: true,
                            granted: _locDone,
                            l10n: l10n,
                            onGrant: _grantLocation,
                          ),
                          _PermRow(
                            icon: Icons.notifications_outlined,
                            title: "Notifications",
                            mandatory: true,
                            granted: _notifDone,
                            l10n: l10n,
                            onGrant: _grantNotification,
                          ),
                          _PermRow(
                            icon: Icons.directions_run,
                            title: "Physical Activity",
                            mandatory: true,
                            granted: _activityDone,
                            l10n: l10n,
                            onGrant: _grantActivity,
                          ),
                          _PermRow(
                            icon: Icons.sensors,
                            title: "Motion Sensors",
                            mandatory: true,
                            granted: _sensorsDone,
                            l10n: l10n,
                            onGrant: _grantSensors,
                          ),
                          _PermRow(
                            icon: Icons.battery_charging_full,
                            title: l10n.batteryDialogTitle,
                            mandatory: true,
                            granted: _batteryDone,
                            l10n: l10n,
                            onGrant: _grantBattery,
                          ),
                          _PermRow(
                            icon: Icons.lock_open_outlined,
                            title: l10n.fullScreenIntentTitle,
                            mandatory: false,
                            granted: _fullScreenDone,
                            l10n: l10n,
                            onGrant: _grantFullScreen,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showWhyPermissions,
                  icon: const Icon(Icons.help_outline, size: 16, color: Colors.white38),
                  label: Text(l10n.whyPermsTitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 4),
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
  final bool mandatory;
  final bool granted;
  final AppLocalizations l10n;
  final VoidCallback onGrant;

  const _PermRow({
    required this.icon,
    required this.title,
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            height: 32,
            child: granted
                ? Center(
                    child: Text(
                      '✓',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  )
                : ElevatedButton(
                    onPressed: onGrant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n.onboardingGrant,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
