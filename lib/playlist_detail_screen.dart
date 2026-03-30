import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart';

import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'song_context_menu.dart';
import 'mini_player.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String name;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.name,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song>? _songs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<SubsonicService>();
      List<Song> songs;
      if (widget.playlistId == 'starred') {
        songs = await service.getStarredSongs();
      } else {
        final playlist = await service.getPlaylist(widget.playlistId);
        songs = playlist?.songs ?? [];
      }
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          if (_songs != null && _songs!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: () {
                final audioSync = context.read<AudioProvider>();
                final shuffled = List<Song>.from(_songs!)..shuffle();
                audioSync.playList(shuffled, 0);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadPlaylist,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_songs == null || _songs!.isEmpty) {
      return const Center(child: Text('Playlist is empty.'));
    }

    return ListView.builder(
      itemCount: _songs!.length,
      itemBuilder: (context, index) {
        final song = _songs![index];
        return ListTile(
          leading: Consumer<SubsonicService>(
            builder: (context, service, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  service.getCoverArtUrl(song.coverArt),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey,
                    child: const Icon(Icons.music_note),
                  ),
                ),
              );
            },
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showSongContextMenu(context, song),
          ),
          onTap: () {
            context.read<AudioProvider>().playList(_songs!, index);
          },
        );
      },
    );
  }
}
