import 'dart:ui'; // Necesario para PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oksigenia_sos/l10n/app_localizations.dart'; 
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkPermissions();
    
    // Esperamos un frame para asegurar que la UI está lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectCountryPrefix();
    });
  }

  void _detectCountryPrefix() {
    // Si el campo tiene texto, no lo tocamos
    if (_phoneController.text.isNotEmpty) return;

    try {
      // Método más robusto para obtener el país sin depender del contexto visual
      final Locale deviceLocale = PlatformDispatcher.instance.locale;
      final String countryCode = deviceLocale.countryCode ?? "ES";
      
      const Map<String, String> prefixes = {
        "ES": "+34", "FR": "+33", "PT": "+351", "DE": "+49", 
        "IT": "+39", "UK": "+44", "US": "+1", "AR": "+54", "MX": "+52"
      };
      
      String prefix = prefixes[countryCode.toUpperCase()] ?? "+";
      
      setState(() {
        _phoneController.text = prefix;
      });
    } catch (_) {
      setState(() { _phoneController.text = "+"; });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _loadData() async {
    final prefs = PreferencesService();
    setState(() {
      _contacts = prefs.getContacts();
      _messageController.text = prefs.getSosMessage();
      _selectedInterval = prefs.getUpdateInterval();
      _selectedInactivity = prefs.getInactivityTime();
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.sms.status;
    setState(() { _isSmsPermissionGranted = status.isGranted; });
  }

  void _addContact() async {
    String number = _phoneController.text.trim();
    if (number.length > 3) {
      await PreferencesService().addContact(number);
      _phoneController.clear(); // Borramos
      _detectCountryPrefix();   // Y volvemos a poner el prefijo
      _loadData();
    }
  }

  void _removeContact(String number) async {
    await PreferencesService().removeContact(number);
    _loadData();
  }

  void _saveMessage(String value) async {
    await PreferencesService().setSosMessage(value);
  }

  void _updateInterval(int? newValue) async {
    if (newValue != null) {
      await PreferencesService().setUpdateInterval(newValue);
      setState(() { _selectedInterval = newValue; });
    }
  }

  void _updateInactivity(int? newValue) async {
    if (newValue != null) {
      await PreferencesService().setInactivityTime(newValue);
      setState(() { _selectedInactivity = newValue; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSafeConfig = _contacts.isNotEmpty && _isSmsPermissionGranted;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: isSafeConfig ? Colors.green[700] : Colors.redAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (!_isSmsPermissionGranted)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.permSmsTitle, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 8),
                  Text(l10n.permSmsBody),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings_applications),
                    label: Text(l10n.permSmsButton),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                ],
              ),
            ),

          Text(l10n.contactsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(l10n.contactsSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.contactsAddHint, 
                    border: const OutlineInputBorder(), 
                    prefixIcon: const Icon(Icons.person_add)
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addContact,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: Colors.blue),
              )
            ],
          ),
          
          const SizedBox(height: 10),
          if (_contacts.isEmpty)
            Padding(padding: const EdgeInsets.all(8.0), child: Text(l10n.contactsEmpty, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
          else
            ..._contacts.map((contact) {
              final isMain = contact == _contacts.firstOrNull;
              return Card(
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.contact_phone, color: isMain ? Colors.green : Colors.grey),
                  title: Text(contact, style: TextStyle(fontWeight: isMain ? FontWeight.bold : FontWeight.normal)),
                  subtitle: isMain ? Text(l10n.contactMain, style: const TextStyle(color: Colors.green, fontSize: 12)) : null,
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _removeContact(contact)),
                ),
              );
            }).toList(),

          const Divider(height: 40),

          Text(l10n.messageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(l10n.messageSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 2,
            maxLength: 100,
            decoration: InputDecoration(hintText: l10n.messageHint, border: const OutlineInputBorder()),
            onChanged: _saveMessage,
          ),

          const Divider(height: 40),

          Text(l10n.inactivityTimeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(l10n.inactivityTimeSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedInactivity,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 30, child: Text(l10n.ina30s, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 3600, child: Text(l10n.ina1h)),
                  DropdownMenuItem(value: 7200, child: Text(l10n.ina2h)),
                ],
                onChanged: _updateInactivity,
              ),
            ),
          ),

          const Divider(height: 40),

          Text(l10n.trackingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(l10n.trackingSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedInterval,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.trackOff)),
                  DropdownMenuItem(value: 30, child: Text(l10n.track30)),
                  DropdownMenuItem(value: 60, child: Text(l10n.track60)),
                  DropdownMenuItem(value: 120, child: Text(l10n.track120)),
                ],
                onChanged: _updateInterval,
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}