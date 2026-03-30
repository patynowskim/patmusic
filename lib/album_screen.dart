import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart';

import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'song_context_menu.dart';
import 'mini_player.dart';
import 'artist_detail_screen.dart';

class AlbumScreen extends StatefulWidget {
  final Album album;
  final SubsonicService subsonicService;
  final String? heroTag;

  const AlbumScreen({
    super.key,
    required this.album,
    required this.subsonicService,
    this.heroTag,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<Album> _albumFuture;

  @override
  void initState() {
    super.initState();
    _albumFuture = widget.subsonicService.getAlbum(widget.album.id);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds'
        : '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final coverArtUrl = widget.subsonicService.getCoverArtUrl(
      widget.album.id,
      size: 600,
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return isWide
                    ? _buildWideLayout(context, coverArtUrl)
                    : _buildNarrowLayout(context, coverArtUrl);
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, String coverArtUrl) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          expandedHeight: 320,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: widget.heroTag ?? 'album-cover-${widget.album.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    coverArtUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: const Center(child: Icon(Icons.album, size: 100)),
                    ),
                  ),
                  // Gradient to make text readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              widget.album.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            titlePadding: const EdgeInsets.only(
              left: 16,
              bottom: 16,
              right: 16,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                if (widget.album.artistId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(
                        artistId: widget.album.artistId!,
                        artistName: widget.album.artist,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                widget.album.artist,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        _buildTrackList(),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, String coverArtUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Cover Art & Info)
        Container(
          width: 350,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButton(onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              Hero(
                tag: widget.heroTag ?? 'album-cover-${widget.album.id}',
                child: Material(
                  elevation: 12,
                  shadowColor: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    coverArtUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.album.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.album.artist,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Right Column (Track List)
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 32, right: 32, bottom: 32),
                sliver: _buildTrackList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackList() {
    return FutureBuilder<Album>(
      future: _albumFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.songs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No tracks found on this album.')),
          );
        }

        final songs = snapshot.data!.songs;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = songs[index];
            final audioProvider = context.watch<AudioProvider>();
            final isCurrentSong = audioProvider.currentSong?.id == song.id;
            final isPlaying = audioProvider.isPlaying;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selected: isCurrentSong,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5),
                leading: SizedBox(
                  width: 40,
                  child: Center(
                    child: isCurrentSong && isPlaying
                        ? Icon(
                            Icons.equalizer,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isCurrentSong
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: isCurrentSong
                                      ? FontWeight.bold
                                      : null,
                                ),
                          ),
                  ),
                ),
                title: Text(
                  song.title.isNotEmpty ? song.title : 'Track ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrentSong
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(Duration(seconds: song.duration)),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => showSongContextMenu(context, song),
                    ),
                  ],
                ),
                onTap: () => audioProvider.playSong(song, widget.album),
              ),
            );
          }, childCount: songs.length),
        );
      },
    );
  }
}
