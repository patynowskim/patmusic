import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'settings_service.dart';
import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'app_shell.dart';
import 'audio_handler.dart';

late MyAudioHandler audioHandler;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    final settingsService = SettingsService();
    await settingsService.init();
    
    final subsonicService = SubsonicService(settingsService);

    print('AudioService initializing...');
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.patmusic.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );
    print('AudioService initialized successfully!');

    runApp(
      MultiProvider(
        providers: [
          Provider<SettingsService>.value(value: settingsService),
          ProxyProvider<SettingsService, SubsonicService>(
            update: (_, settings, _) => subsonicService,
          ),
          ChangeNotifierProvider(
            create: (_) => AudioProvider(subsonicService, audioHandler),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error in main: $e\n$stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Text('Error initializing app:\n$e\n$stackTrace', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
  }
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

