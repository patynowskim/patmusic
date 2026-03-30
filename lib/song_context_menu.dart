import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subsonic_api/subsonic_api.dart';

import 'subsonic_service.dart';
import 'audio_provider.dart';
import 'album_screen.dart';
import 'artist_detail_screen.dart';
// Note: We will handle showing artist screen if possible later.

void showSongContextMenu(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return _SongContextMenuSheet(song: song);
    },
  );
}

class _SongContextMenuSheet extends StatefulWidget {
  final Song song;
  const _SongContextMenuSheet({required this.song});

  @override
  State<_SongContextMenuSheet> createState() => _SongContextMenuSheetState();
}

class _SongContextMenuSheetState extends State<_SongContextMenuSheet> {
  bool _isStarred = false;
  bool _isLoadingStar = true;

  @override
  void initState() {
    super.initState();
    _checkStarStatus();
  }

  Future<void> _checkStarStatus() async {
    final service = context.read<SubsonicService>();
    final starred = await service.checkStarred(widget.song.id);
    if (mounted) {
      setState(() {
        _isStarred = starred;
        _isLoadingStar = false;
      });
    }
  }

  void _toggleStar() async {
    final service = context.read<SubsonicService>();
    final wasStarred = _isStarred;
    setState(() {
      _isStarred = !wasStarred;
    });
    try {
      if (wasStarred) {
        await service.unstar(widget.song.id);
      } else {
        await service.star(widget.song.id);
      }
    } catch (_) {
      // Revert upon error
      if (mounted) {
        setState(() {
          _isStarred = wasStarred;
        });
      }
    }
    // We do not pop context here to let user click other things, or we can pop.
    if (mounted) Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isStarred ? 'Added to liked songs' : 'Removed from liked songs',
          ),
        ),
      );
    }
  }

  void _addToPlaylist() async {
    final service = context.read<SubsonicService>();
    final playlists = await service.getPlaylists();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New Playlist'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewPlaylist();
                  },
                ),
                const Divider(),
                ...playlists.map(
                  (playlist) => ListTile(
                    title: Text(playlist.name),
                    onTap: () async {
                      Navigator.pop(context);
                      await service.updatePlaylist(
                        playlist.id,
                        songIdsToAdd: [widget.song.id],
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createNewPlaylist() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Playlist name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.pop(this.context); // pop the bottom sheet

                  try {
                    final service = context.read<SubsonicService>();
                    await service.createPlaylist(name, songId: widget.song.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created playlist $name')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    final theme = Theme.of(context);

    // Some simple icon buttons styled like YouTube Music menu
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header showing current song item loosely
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      context.read<SubsonicService>().getCoverArtUrl(
                        widget.song.coverArt,
                        size: 100,
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.music_note, size: 48),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildActionTile(
              context,
              icon: Icons.radio,
              title: 'Start radio',
              onTap: () {
                Navigator.pop(context);
                final list = [widget.song];
                audioProvider.playList(
                  list,
                  0,
                ); // Will auto-fetch similar if autoplay enabled
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.playlist_play,
              title: 'Play next',
              onTap: () {
                Navigator.pop(context);
                audioProvider.insertNext(widget.song);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.queue_music,
              title: 'Add to queue',
              onTap: () {
                Navigator.pop(context);
                audioProvider.addToQueue(widget.song);
              },
            ),
            _buildActionTile(
              context,
              icon: _isLoadingStar
                  ? Icons.sync
                  : (_isStarred ? Icons.thumb_up : Icons.thumb_up_alt_outlined),
              title: _isStarred
                  ? 'Remove from liked songs'
                  : 'Add to liked songs',
              onTap: _isLoadingStar ? null : _toggleStar,
            ),
            _buildActionTile(
              context,
              icon: Icons.playlist_add,
              title: 'Save to playlist',
              onTap: _addToPlaylist,
            ),
            if (widget.song.albumId.isNotEmpty)
              _buildActionTile(
                context,
                icon: Icons.album,
                title: 'Show album',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final service = context.read<SubsonicService>();
                    final album = await service.getAlbum(widget.song.albumId);
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
                  } catch (_) {}
                },
              ),
            _buildActionTile(
              context,
              icon: Icons.high_quality,
              title: 'Audio quality',
              onTap: () {
                Navigator.pop(context);
                _showQualityMenu(context, audioProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityMenu(BuildContext context, AudioProvider ap) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Audio Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Original (No Transcoding)'),
                onTap: () {
                  ap.setSessionBitRate(null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('320 kbps (High)'),
                onTap: () {
                  ap.setSessionBitRate(320);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('192 kbps (Medium)'),
                onTap: () {
                  ap.setSessionBitRate(192);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('128 kbps (Low)'),
                onTap: () {
                  ap.setSessionBitRate(128);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('64 kbps (Very Low)'),
                onTap: () {
                  ap.setSessionBitRate(64);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('32 kbps (Minimum)'),
                onTap: () {
                  ap.setSessionBitRate(32);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

