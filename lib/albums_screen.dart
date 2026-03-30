import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart';

import 'subsonic_service.dart';
import 'album_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<Album>? _newestAlbums;
  List<Album>? _randomAlbums;
  List<Album>? _frequentAlbums;
  List<Album>? _recentAlbums;
  List<dynamic>? _artists;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService = context.read<SubsonicService>();
      
      final newest = await subsonicService.getAlbumList2(type: 'newest', size: 15);
      final random = await subsonicService.getAlbumList2(type: 'random', size: 15);
      final frequent = await subsonicService.getAlbumList2(type: 'frequent', size: 15);
      final recent = await subsonicService.getAlbumList2(type: 'recent', size: 15);
      
      List<dynamic> allArtists = [];
      try {
        allArtists = await subsonicService.getArtists();
        allArtists.shuffle();
        if (allArtists.length > 15) {
          allArtists = allArtists.sublist(0, 15);
        }
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _newestAlbums = newest;
          _randomAlbums = random;
          _frequentAlbums = frequent;
          _recentAlbums = recent;
          _artists = allArtists;
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          if (_newestAlbums != null && _newestAlbums!.isNotEmpty) ...[
            _buildCategoryHeader('New Releases'),
            _buildHorizontalList(_newestAlbums!, 'new'),
            const SizedBox(height: 32),
          ],
          
          if (_recentAlbums != null && _recentAlbums!.isNotEmpty) ...[
            _buildCategoryHeader('Recently Played'),
            _buildHorizontalList(_recentAlbums!, 'rec'),
            const SizedBox(height: 32),
          ],
          
          if (_randomAlbums != null && _randomAlbums!.isNotEmpty) ...[
            _buildCategoryHeader('Mixed for you'),
            _buildHorizontalList(_randomAlbums!, 'mix'),
            const SizedBox(height: 32),
          ],

          if (_artists != null && _artists!.isNotEmpty) ...[
            _buildCategoryHeader('Featured Artists'),
            _buildArtistsList(_artists!),
            const SizedBox(height: 32),
          ],
          
          if (_frequentAlbums != null && _frequentAlbums!.isNotEmpty) ...[
            _buildCategoryHeader('Frequently Played'),
            _buildHorizontalList(_frequentAlbums!, 'freq'),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistsList(List<dynamic> artists) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final hasCover = artist['coverArt'] != null;
          final coverUrl = hasCover 
            ? context.read<SubsonicService>().getCoverArtUrl(artist['coverArt'], size: 200)
            : '';

          return Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(60),
              onTap: () {
                // Future expansion: Navigate to Artist view
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      image: hasCover ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: !hasCover ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artist['name'] ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Album> albums, String tagPrefix) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          final coverArtUrl = context.read<SubsonicService>().getCoverArtUrl(album.id, size: 200);

          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                      AlbumScreen(
                        album: album,
                        subsonicService: context.read<SubsonicService>(),
                        heroTag: 'album-cover-$tagPrefix-${album.id}',
                      ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: 'album-cover-$tagPrefix-${album.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(coverArtUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
