import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart';
import '../services/preferences_service.dart';
import '../logic/sos_logic.dart';
import '../logic/activity_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  List<String> _contacts = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _selectedInterval = 0;
  int _selectedInactivity = 3600;
  bool _isSmsPermissionGranted = true;
  bool _isLiveTrackingActive = false;
  int _liveTrackingInterval = 30;
  int _liveTrackingShutdown = 0;
  ActivityProfile _selectedProfile = ActivityProfile.trekking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkPermissions();
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectCountryPrefix());
  }

  void _detectCountryPrefix() {
    if (_phoneController.text.isNotEmpty) return;
    const Map<String, String> prefixes = {
      'ES': '+34', 'FR': '+33', 'PT': '+351', 'DE': '+49', 'IT': '+39',
      'GB': '+44', 'UK': '+44', 'US': '+1', 'CA': '+1', 'MX': '+52',
      'AR': '+54', 'CO': '+57', 'CL': '+56', 'PE': '+51',
      'NL': '+31', 'SE': '+46', 'NO': '+47', 'CH': '+41', 'AT': '+43',
    };

    final countryCode = (PlatformDispatcher.instance.locale.countryCode ?? '').toUpperCase();
    if (prefixes.containsKey(countryCode)) {
      setState(() {
        _phoneController.text = prefixes[countryCode]!;
      });
    }
  }

  // 🛡️ VALIDADOR DE NÚMEROS
  bool _isValidPhoneNumber(String input) {
    String cleanInput = input.trim();
    if (cleanInput.isEmpty) return false;

    // 1. Regex: Solo permite números, +, espacios y guiones
    final RegExp validCharacters = RegExp(r'^[+0-9\-\s]+$');
    if (!validCharacters.hasMatch(cleanInput)) return false;

    // 2. Conteo de dígitos reales:
    String justDigits = cleanInput.replaceAll(RegExp(r'[^0-9]'), '');
    return justDigits.length >= 6;
  }

  // 💡 NUEVO: Diálogo de ayuda para permisos restringidos (Android 13+)
  void _showPermissionGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogPermissionTitle), // "Cómo activar..."
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dialogPermissionStep1),
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep2, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep3),
            const SizedBox(height: 8),
            Text(l10n.dialogPermissionStep4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.dialogClose ?? "Cerrar"), // Usamos dialogClose genérico si existe, o hardcode fallback
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Ahora sí vamos a ajustes
            },
            child: Text(l10n.btnGoToSettings),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Auto-guardado al salir (CON VALIDACIÓN)
    String pendingPhone = _phoneController.text.trim();
    if (_isValidPhoneNumber(pendingPhone) && !_contacts.contains(pendingPhone)) {
       PreferencesService().addContact(pendingPhone);
    }

    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.sms.status;
    setState(() {
      _isSmsPermissionGranted = status.isGranted;
    });
  }

  Future<void> _loadData() async {
    final prefs = PreferencesService();
    setState(() {
      _contacts = prefs.getContacts();
      _selectedInterval = prefs.getUpdateInterval();
      _selectedInactivity = prefs.getInactivityTime();
      _messageController.text = prefs.getSosMessage();
      _isLiveTrackingActive = prefs.getLiveTrackingEnabled();
      _liveTrackingInterval = prefs.getLiveTrackingIntervalMinutes();
      _liveTrackingShutdown = prefs.getLiveTrackingShutdownMinutes();
      _selectedProfile = prefs.getActivityProfile();
    });
  }

  Future<void> _updateActivityProfile(ActivityProfile? profile) async {
    if (profile == null) return;
    setState(() => _selectedProfile = profile);
    await PreferencesService().saveActivityProfile(profile);
    // Re-arm Sylvia with the new profile if monitoring is active.
    if (mounted) {
      final logic = Provider.of<SOSLogic>(context, listen: false);
      if (logic.isFallDetectionActive || logic.isInactivityMonitorActive) {
        logic.reapplyMonitoringConfig();
      }
    }
  }

  String _profileLabel(AppLocalizations l10n, ActivityProfile p) {
    switch (p) {
      case ActivityProfile.trekking: return l10n.profileTrekking;
      case ActivityProfile.trailMtb: return l10n.profileTrailMtb;
      case ActivityProfile.mountaineering: return l10n.profileMountaineering;
      case ActivityProfile.paragliding: return l10n.profileParagliding;
      case ActivityProfile.kayak: return l10n.profileKayak;
      case ActivityProfile.equitation: return l10n.profileEquitation;
      case ActivityProfile.professional: return l10n.profileProfessional;
    }
  }

  String _profileDescription(AppLocalizations l10n, ActivityProfile p) {
    switch (p) {
      case ActivityProfile.trekking: return l10n.profileTrekkingDesc;
      case ActivityProfile.trailMtb: return l10n.profileTrailMtbDesc;
      case ActivityProfile.mountaineering: return l10n.profileMountaineeringDesc;
      case ActivityProfile.paragliding: return l10n.profileParaglidingDesc;
      case ActivityProfile.kayak: return l10n.profileKayakDesc;
      case ActivityProfile.equitation: return l10n.profileEquitationDesc;
      case ActivityProfile.professional: return l10n.profileProfessionalDesc;
    }
  }

  void _addContact() {
    final l10n = AppLocalizations.of(context)!;

    // 1. Chequeo de Permisos
    if (!_isSmsPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ ${l10n.permSmsText}"), backgroundColor: Colors.red)
      );
      return;
    }

    String phone = _phoneController.text.trim();

    // 2. Chequeo de Validación (Usando la traducción nueva)
    if (!_isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ ${l10n.invalidNumberWarning}"), 
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        )
      );
      return;
    }

    // 3. Añadir si no está repetido
    if (!_contacts.contains(phone)) {
      setState(() {
        _contacts.add(phone);
        _phoneController.clear();
      });
      PreferencesService().addContact(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Contacto duplicado / Duplicate"))
      );
    }
  }

  void _removeContact(String phone) {
    setState(() {
      _contacts.remove(phone);
    });
    PreferencesService().removeContact(phone);
  }

  void _updateInterval(int? value) {
    if (value != null) {
      setState(() => _selectedInterval = value);
      PreferencesService().setUpdateInterval(value);
    }
  }

  void _updateInactivity(int? value) {
    if (value != null) {
      setState(() => _selectedInactivity = value);
      PreferencesService().setInactivityTime(value);
    }
  }

  void _saveMessage(String value) {
    PreferencesService().setSosMessage(value);
  }

  void _toggleLiveTracking(BuildContext context, AppLocalizations l10n) {
    final sosLogic = context.read<SOSLogic>();
    if (_isLiveTrackingActive) {
      sosLogic.disableLiveTracking();
      setState(() => _isLiveTrackingActive = false);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.liveTrackingLegalTitle),
          content: Text(l10n.liveTrackingLegalBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.btnDecline),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                sosLogic.enableLiveTracking(_liveTrackingInterval, _liveTrackingShutdown);
                setState(() => _isLiveTrackingActive = true);
              },
              child: Text(l10n.liveTrackingActivate),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSettings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCION DE PERMISOS
            if (!_isSmsPermissionGranted)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.permSmsText, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      // 👇 AQUÍ SE ACTIVA EL TUTORIAL
                      onPressed: () => _showPermissionGuide(context),
                      icon: const Icon(Icons.settings_applications),
                      label: Text(l10n.permSmsButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),

            Text(l10n.contactsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phoneLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _addContact(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addContact,
                  child: const Icon(Icons.add), 
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // LISTA DE CONTACTOS CON JERARQUÍA VISUAL
            if (_contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(l10n.noContacts, style: const TextStyle(color: Colors.red)),
              )
            else
              ..._contacts.asMap().entries.map((entry) {
                int index = entry.key;
                String phone = entry.value;
                bool isPrimary = (index == 0);

                return Card(
                  elevation: isPrimary ? 2 : 0,
                  color: isPrimary ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : null,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: isPrimary 
                      ? const Icon(Icons.star, color: Colors.amber, size: 28) 
                      : const Icon(Icons.person),
                    title: Text(
                      phone,
                      style: TextStyle(
                        fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                        fontSize: isPrimary ? 18 : 16,
                      ),
                    ),
                    subtitle: isPrimary 
                      ? Text(l10n.contactMain, style: TextStyle(color: Colors.amber[800], fontSize: 12)) 
                      : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContact(phone),
                    ),
                  ),
                );
              }),

            const Divider(height: 40),

            Text(l10n.messageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(l10n.messageSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)), 
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: l10n.messageHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: _saveMessage,
              maxLines: 3,
            ),

            const Divider(height: 40),

            Text(l10n.activityProfileTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(l10n.activityProfileSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ActivityProfile>(
                  value: _selectedProfile,
                  isExpanded: true,
                  items: ActivityProfile.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(_profileLabel(l10n, p)),
                  )).toList(),
                  onChanged: _updateActivityProfile,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _profileDescription(l10n, _selectedProfile),
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
            ),

            const Divider(height: 40),

            Text(l10n.inactivityTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(l10n.inactivitySubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedInactivity,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 30, child: Text("TEST (30s)", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 3600, child: Text(l10n.ina1h)),
                    DropdownMenuItem(value: 7200, child: Text(l10n.ina2h)),
                  ],
                  onChanged: _updateInactivity,
                ),
              ),
            ),
            
            const Divider(height: 40),

            Text(l10n.liveTrackingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(l10n.liveTrackingSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),

            // Interval selector
            Text(l10n.liveTrackingInterval, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _liveTrackingInterval,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 1, child: Text(l10n.liveTrackingTest1m, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 2, child: Text(l10n.liveTrackingTest2m, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 30, child: Text(l10n.track30)),
                    DropdownMenuItem(value: 60, child: Text(l10n.track60)),
                    DropdownMenuItem(value: 120, child: Text(l10n.track120)),
                  ],
                  onChanged: _isLiveTrackingActive ? null : (v) {
                    if (v != null) setState(() => _liveTrackingInterval = v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Shutdown reminder selector
            Text(l10n.liveTrackingShutdownReminder, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _liveTrackingShutdown,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 0, child: Text(l10n.liveTrackingNoReminder)),
                    DropdownMenuItem(value: 120, child: Text(l10n.liveTrackingReminder2h)),
                    DropdownMenuItem(value: 180, child: Text(l10n.liveTrackingReminder3h)),
                    DropdownMenuItem(value: 240, child: Text(l10n.liveTrackingReminder4h)),
                    DropdownMenuItem(value: 300, child: Text(l10n.liveTrackingReminder5h)),
                  ],
                  onChanged: _isLiveTrackingActive ? null : (v) {
                    if (v != null) setState(() => _liveTrackingShutdown = v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_isLiveTrackingActive ? Icons.stop_circle : Icons.play_circle_filled),
                label: Text(_isLiveTrackingActive ? l10n.liveTrackingDeactivate : l10n.liveTrackingActivate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLiveTrackingActive ? Colors.red[700] : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _contacts.isEmpty
                    ? null
                    : () => _toggleLiveTracking(context, l10n),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}