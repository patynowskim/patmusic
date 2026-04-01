import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio_provider.dart';
import 'subsonic_service.dart';
import 'audio_effects_sheet.dart';
import 'song_context_menu.dart';
import 'album_screen.dart';
import 'artist_detail_screen.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  int _activeTab = 0; // 0 = Cover, 1 = Lyrics, 2 = Up Next
  Map<String, dynamic>? _lyricsData;
  bool _isLoadingLyrics = false;
  bool _isStarred =
      false; // Note: would need deeper state integration to persist
  String? _lastSongId;
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveLyricIndex = -1;

  @override
  void initState() {
    super.initState();
    final ap = context.read<AudioProvider>();
    _lastSongId = ap.currentSong?.id;
    _checkStarStatus(_lastSongId);
    ap.addListener(_onAudioProviderChange);
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _onAudioProviderChange() {
    if (!mounted) return;
    final ap = context.read<AudioProvider>();
    if (ap.currentSong?.id != _lastSongId) {
      setState(() {
        _lastSongId = ap.currentSong?.id;
        _lyricsData = null;
        _isStarred = false; // Reset before loading
      });
      _checkStarStatus(ap.currentSong?.id);

      // On wide screens we might show lyrics even if _activeTab is 0
      final isWide = MediaQuery.of(context).size.width > 800;
      if (_activeTab == 1 || (isWide && _activeTab == 0)) {
        _fetchLyrics(ap);
      }
    }
  }

  Future<void> _checkStarStatus(String? songId) async {
    if (songId == null) return;
    final service = context.read<SubsonicService>();
    final isStarred = await service.checkStarred(songId);
    if (mounted && _lastSongId == songId) {
      setState(() {
        _isStarred = isStarred;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration < Duration.zero) duration = Duration.zero;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds'
        : '$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _fetchLyrics(AudioProvider ap) async {
    final song = ap.currentSong;
    if (song == null) return;

    setState(() {
      _isLoadingLyrics = true;
      _lyricsData = null;
      _lastActiveLyricIndex = -1;
    });

    final service = context.read<SubsonicService>();
    final fetched = await service.getLyrics(song.artist, song.title, song.id);

    if (mounted) {
      setState(() {
        _lyricsData =
            fetched ??
            {'type': 'plain', 'data': 'No lyrics available for this track.'};
        _isLoadingLyrics = false;
      });
    }
  }

  void _toggleStar(AudioProvider ap) {
    final song = ap.currentSong;
    if (song == null) return;

    final service = context.read<SubsonicService>();
    setState(() {
      _isStarred = !_isStarred;
    });

    if (_isStarred) {
      service.star(song.id).catchError((_) {});
    } else {
      service.unstar(song.id).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    final subsonicService = context.read<SubsonicService>();
    final coverArtUrl = subsonicService.getCoverArtUrl(song.id, size: 800);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Song',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Video',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AudioEffectsSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              if (audioProvider.currentSong != null) {
                showSongContextMenu(context, audioProvider.currentSong!);
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! > 15) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred Background
            Image.network(
              coverArtUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Center(child: Icon(Icons.music_note)),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return _buildWideLayout(
                        context, audioProvider, coverArtUrl);
                  }
                  return _buildNarrowLayout(
                      context, audioProvider, coverArtUrl);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    AudioProvider audioProvider,
    String coverArtUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Main Content Area based on Tabs
          Expanded(
            flex: 8,
            child: _buildTabContent(audioProvider, coverArtUrl),
          ),
          const SizedBox(height: 32),
          _buildControls(context, audioProvider),
          const SizedBox(height: 16),
          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(
                0,
                'Player',
                () => setState(() => _activeTab = 0),
              ),
              _buildTabButton(1, 'Lyrics', () {
                setState(() {
                  _activeTab = 1;
                  _lastActiveLyricIndex = -1;
                });
                if (_lyricsData == null) _fetchLyrics(audioProvider);
              }),
              _buildTabButton(
                2,
                'Up Next',
                () => setState(() => _activeTab = 2),
              ),
            ],
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    AudioProvider audioProvider,
    String coverArtUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Album Art
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: 'mini-player-art',
                      child: Material(
                        elevation: 20,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          coverArtUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          // Right side: Controls and Info
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildControls(context, audioProvider),
                const SizedBox(height: 48),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildTabButton(
                                2,
                                'Up Next',
                                () => setState(() => _activeTab = 2),
                                useBackground: false,
                              ),
                              const SizedBox(width: 16),
                              _buildTabButton(1, 'Lyrics', () {
                                setState(() {
                                  _activeTab = 1;
                                  _lastActiveLyricIndex = -1;
                                });
                                if (_lyricsData == null)
                                  _fetchLyrics(audioProvider);
                              }, useBackground: false),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        Expanded(
                          child: _activeTab == 2
                              ? _buildUpNextTab(audioProvider)
                              : _buildLyricsTab(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    int index,
    String text,
    VoidCallback onTap, {
    bool useBackground = true,
  }) {
    final isActive = _activeTab == index;
    if (!useBackground) {
      return TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 18,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isActive
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white54,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTabContent(AudioProvider ap, String coverArtUrl) {
    if (_activeTab == 0) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Hero(
            tag: 'mini-player-art',
            child: Material(
              elevation: 20,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                coverArtUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, size: 100),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (_activeTab == 1) {
      return _buildLyricsTab();
    } else {
      return _buildUpNextTab(ap);
    }
  }

  Widget _buildLyricsTab() {
    if (_isLoadingLyrics)
      return const Center(child: CircularProgressIndicator());

    // Auto-fetch if rendering this tab and data is still null
    if (_lyricsData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lyricsData == null && !_isLoadingLyrics) {
          _fetchLyrics(context.read<AudioProvider>());
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (_lyricsData!['type'] == 'structured') {
      final List<dynamic> lines = _lyricsData!['data'];
      if (lines.isEmpty) {
        return const Center(
          child: Text('Brak napisów.', style: TextStyle(color: Colors.white70)),
        );
      }
      return Consumer<AudioProvider>(
        builder: (context, ap, _) {
          final posMs = ap.position.inMilliseconds;
          int activeIndex = -1;
          for (int i = 0; i < lines.length; i++) {
            final startVal = lines[i]['start'];
            int startMs = -1;
            if (startVal is int)
              startMs = startVal;
            else if (startVal is String)
              startMs = int.tryParse(startVal) ?? -1;

            if (startMs >= 0 && startMs <= posMs) {
              activeIndex = i;
            } else if (startMs > posMs) {
              break; // lyrics are usually sorted
            }
          }

          // Force scroll if the active index changes
          if (activeIndex != -1 && activeIndex != _lastActiveLyricIndex) {
            _lastActiveLyricIndex = activeIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_lyricsScrollController.hasClients) {
                // Approximate item height is ~45-50.
                final double targetOffset = (activeIndex * 48.0) -
                    (MediaQuery.of(context).size.height * 0.15) +
                    50.0; // Account for top padding offset

                _lyricsScrollController.animateTo(
                  targetOffset.clamp(
                    0.0,
                    _lyricsScrollController.position.maxScrollExtent,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }

          return ListView.builder(
            controller: _lyricsScrollController,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 100, // Make the first lines appear a bit lower
              bottom: 300, // Make the bottom lyrics not hide mostly
            ),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isActive = index == activeIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isActive ? 28 : 22,
                    height: 1.4,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  child: Text(line['value'] ?? ''),
                ),
              );
            },
          );
        },
      );
    }

    final plainText = _lyricsData!['data']?.toString().trim() ?? '';
    if (plainText.isEmpty ||
        plainText == 'No lyrics available for this track.') {
      return const Center(
        child: Text('Brak napisów.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          plainText,
          style: const TextStyle(
            fontSize: 22,
            height: 1.6,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpNextTab(AudioProvider ap) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: ap.queue.length,
      itemBuilder: (context, index) {
        final song = ap.queue[index];
        final isPlaying = ap.currentSong?.id == song.id;
        return ListTile(
          selected: isPlaying,
          selectedTileColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: isPlaying
              ? const Icon(Icons.equalizer, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white54),
                ),
          title: Text(
            song.title,
            style: TextStyle(
              color: isPlaying ? Colors.white : Colors.white70,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            song.artist,
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () {
            // Can technically tap to skip directly, but we just implemented previous/next
            // For now just visually show queue
          },
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, AudioProvider audioProvider) {
    final song = audioProvider.currentSong!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Actions
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.explicit,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  if (song.artistId != null) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ArtistDetailScreen(
                                          artistId: song.artistId!,
                                          artistName: song.artist,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  song.artist,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                              ),
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: () async {
                                  if (song.albumId != null) {
                                    Navigator.pop(context); // close player
                                    final service = context
                                        .read<SubsonicService>();
                                    final album = await service.getAlbum(
                                      song.albumId!,
                                    );
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AlbumScreen(
                                            album: album,
                                            subsonicService: service,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  song.album,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.thumb_down_alt_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    _isStarred ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _toggleStar(audioProvider),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Seek Bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: audioProvider.position.inSeconds.toDouble().clamp(
              0.0,
              audioProvider.duration.inSeconds.toDouble() > 0
                  ? audioProvider.duration.inSeconds.toDouble()
                  : 1.0,
            ),
            max: audioProvider.duration.inSeconds.toDouble() > 0
                ? audioProvider.duration.inSeconds.toDouble()
                : 1.0,
            onChanged: (value) {
              audioProvider.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),

        // Durations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(audioProvider.position),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            Text(
              _formatDuration(audioProvider.duration),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Play Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.shuffle, color: audioProvider.isShuffle ? Colors.white : Colors.white.withValues(alpha: 0.6)),
              onPressed: () => audioProvider.toggleShuffle(),
            ),
            IconButton(
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () => audioProvider.skipPrevious(),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                color: Colors.black,
                onPressed: () => audioProvider.playPause(),
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 38,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
              onPressed: () => audioProvider.skipNext(),
            ),
            IconButton(
              icon: Icon(
                audioProvider.repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
                color: audioProvider.repeatMode != 0 ? Colors.white : Colors.white.withValues(alpha: 0.6),
              ),
              onPressed: () => audioProvider.toggleRepeat(),
            ),
          ],
        ),
      ],
    );
  }
}



