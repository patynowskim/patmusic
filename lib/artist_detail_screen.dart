import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'subsonic_service.dart';
import 'album_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  Map<String, dynamic>? _artistData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtist();
  }

  Future<void> _loadArtist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = context.read<SubsonicService>();
      final data = await subsonicService.getArtist(widget.artistId);
      setState(() {
        _artistData = data;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
      ),
      body: _buildBody(),
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
            Text('Error loading artist: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArtist,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final albums = _artistData?['album'] as List<dynamic>? ?? [];

    if (albums.isEmpty) {
      return const Center(child: Text('No albums found for this artist.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final subsonicService = context.read<SubsonicService>();
        final coverArtUrl = subsonicService.getCoverArtUrl(album['coverArt'] ?? '');

        return GestureDetector(
          onTap: () async {
            final fetchedAlbum = await subsonicService.getAlbum(album['id']);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumScreen(
                    album: fetchedAlbum,
                    subsonicService: subsonicService,
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverArtUrl.isNotEmpty
                      ? Image.network(
                          coverArtUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 50),
                        )
                      : const Icon(Icons.album, size: 50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album['name'] ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (album['year'] != null)
                Text(
                  '${album['year']}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }
}
