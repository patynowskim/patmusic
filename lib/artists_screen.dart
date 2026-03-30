import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'subsonic_service.dart';
import 'artist_detail_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  List<dynamic>? _artists;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = context.read<SubsonicService>();
      final artists = await subsonicService.getArtists();
      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
            ElevatedButton(onPressed: _loadArtists, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_artists == null || _artists!.isEmpty) {
      return const Center(child: Text('No artists found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      child: ListView.builder(
        itemCount: _artists!.length,
        itemBuilder: (context, index) {
          final artist = _artists![index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(artist['name'] ?? 'Unknown Artist', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${artist['albumCount'] ?? 0} albums'),
            onTap: () {
              if (artist['id'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(
                      artistId: artist['id'],
                      artistName: artist['name'] ?? 'Unknown Artist',
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}


