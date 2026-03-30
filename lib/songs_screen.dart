import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart';
import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'song_context_menu.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<Song>? _songs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = context.read<SubsonicService>();
      final songs = await subsonicService.getRandomSongs(size: 50);
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadSongs, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_songs == null || _songs!.isEmpty) {
      return const Center(child: Text('No songs found.'));
    }

    final audioProvider = context.watch<AudioProvider>();

    return RefreshIndicator(
      onRefresh: _loadSongs,
      child: ListView.builder(
        itemCount: _songs!.length,
        itemBuilder: (context, index) {
          final song = _songs![index];
          final isCurrentSong = audioProvider.currentSong?.id == song.id;

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                context.read<SubsonicService>().getCoverArtUrl(song.id, size: 100),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.music_note, size: 48),
              ),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                color: isCurrentSong ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatDuration(song.duration)),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showSongContextMenu(context, song),
                ),
              ],
            ),
            onTap: () {
              // Creating a dummy album just to pass it
              audioProvider.playSong(song, Album(
                id: song.albumId, name: song.album, coverArt: song.coverArt,
                songCount: 1, created: song.created, duration: song.duration,
                artist: song.artist, artistId: song.artistId, songs: [song]
              ));
            },
          );
        },
      ),
    );
  }
}
