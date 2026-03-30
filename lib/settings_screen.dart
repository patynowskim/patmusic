import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _endpointController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  int _selectedBitRate = 0;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _endpointController = TextEditingController(text: settings.endpoint);
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _selectedBitRate = settings.maxBitRate;
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settings = context.read<SettingsService>();
    await settings.saveSettings(
      endpoint: _endpointController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      maxBitRate: _selectedBitRate,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved. Restart to apply.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'Subsonic Endpoint',
              border: OutlineInputBorder(),
              hintText: 'http://127.0.0.1:4533',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Audio Quality (Transcoding)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _selectedBitRate,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              helperText: 'Select the maximum bitrate for audio streaming. Lower values save data.',
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Original (No limit)')),
              DropdownMenuItem(value: 320, child: Text('320 kbps (High)')),
              DropdownMenuItem(value: 192, child: Text('192 kbps (Medium)')),
              DropdownMenuItem(value: 128, child: Text('128 kbps (Low/Cellular)')),
              DropdownMenuItem(value: 64, child: Text('64 kbps (Very Low)')),
              DropdownMenuItem(value: 32, child: Text('32 kbps (Minimum)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedBitRate = value;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
