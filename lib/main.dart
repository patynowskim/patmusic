import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'settings_service.dart';
import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        ProxyProvider<SettingsService, SubsonicService>(
          update: (_, settings, _) => SubsonicService(settings),
        ),
        ChangeNotifierProxyProvider<SubsonicService, AudioProvider>(
          create: (context) => AudioProvider(SubsonicService(settingsService)),
          update: (_, subsonic, previous) {
            return previous ?? AudioProvider(subsonic);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PatMusic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark, // YouTube music clone style
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

