import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart'; // Add Song and Album models if mapped, here we just read raw JSON for simplicity or map it 
import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'mini_player.dart';

class GlobalSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildSearchResults(context)),
        const MiniPlayer(),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return Column(
        children: [
          const Expanded(child: Center(child: Text('Type at least 2 characters to search'))),
          const MiniPlayer(),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: _buildSearchResults(context)),
        const MiniPlayer(),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final service = context.read<SubsonicService>();
    final ap = context.read<AudioProvider>();

    return FutureBuilder<Map<String, dynamic>>(
      future: service.search3(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? {};
        final songs = (data['song'] as List?) ?? [];
        final albums = (data['album'] as List?) ?? [];
        final artists = (data['artist'] as List?) ?? [];

        if (songs.isEmpty && albums.isEmpty && artists.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (artists.isNotEmpty) ...[
              const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...artists.map((a) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(a['name'] ?? ''),
                onTap: () {},
              )),
              const Divider(),
            ],
            if (albums.isNotEmpty) ...[
              const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...albums.map((a) => ListTile(
                leading: Image.network(service.getCoverArtUrl(a['id'], size: 50), width: 50, height: 50),
                title: Text(a['name'] ?? ''),
                subtitle: Text(a['artist'] ?? ''),
                onTap: () {},
              )),
              const Divider(),
            ],
            if (songs.isNotEmpty) ...[
              const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...songs.map((s) => ListTile(
                leading: Image.network(service.getCoverArtUrl(s['id'], size: 50), width: 50, height: 50),
                title: Text(s['title'] ?? ''),
                subtitle: Text(s['artist'] ?? ''),
                onTap: () {
                  final song = Song(
                    id: s['id'], parent: '', title: s['title'] ?? '', album: s['album'] ?? '',
                    artist: s['artist'] ?? '', isDir: false, coverArt: s['coverArt'] ?? '',
                    created: '', duration: s['duration'] ?? 0, bitRate: 0, size: 0,
                    suffix: '', contentType: '', isVideo: false, path: '', albumId: s['albumId'] ?? '',
                    artistId: s['artistId'] ?? '', type: '', played: ''
                  );
                  ap.playSong(song, null);
                },
              )),
            ],
          ],
        );
      },
    );
  }
}
