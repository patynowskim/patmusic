import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:subsonic_api/subsonic_api.dart';
import 'subsonic_service.dart';

class AudioProvider extends ChangeNotifier {
  final Player _audioPlayer = Player(configuration: const PlayerConfiguration(pitch: true));
  final SubsonicService subsonicService;

  List<Song> _queue = [];
  int _currentIndex = -1;
  Album? _currentAlbum;
  
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Audio stream options
  int? _sessionBitRate;
  double _pitch = 1.0;
  double _speed = 1.0;

  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  // 0: None, 1: All, 2: One
  int _repeatMode = 0;
  int get repeatMode => _repeatMode;

  // Track scrobbling state to prevent multiple submissions for same play
  bool _hasScrobbledCurrent = false;

  AudioProvider(this.subsonicService) {
    _audioPlayer.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _audioPlayer.stream.completed.listen((completed) {
      if (completed) {
        _playNext();
      }
    });

    _audioPlayer.stream.duration.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _audioPlayer.stream.position.listen((newPosition) {
      _position = newPosition;
      _checkScrobble();
      notifyListeners();
    });
  }

  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  Album? get currentAlbum => _currentAlbum;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  
  int? get sessionBitRate => _sessionBitRate;
  double get pitch => _pitch;
  double get speed => _speed;
  List<Song> get queue => _queue;

  void setSessionBitRate(int? bitRate) {
    _sessionBitRate = bitRate;
    notifyListeners();
    // Restart current stream to apply bitrate if playing
    if (currentSong != null) {
      final pos = _position;
      final wasPlaying = _isPlaying;
      _loadCurrentTrack(autoPlay: wasPlaying, initialPosition: pos);
    }
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    try {
      await _audioPlayer.setPitch(pitch);
    } catch (e) {
      if (kDebugMode) print('Pitch not supported on this platform: $e');
    }
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    try {
      await _audioPlayer.setRate(speed);
    } catch (e) {
      if (kDebugMode) print('Speed not supported on this platform: $e');
    }
    notifyListeners();
  }

  Future<void> _loadCurrentTrack({bool autoPlay = true, Duration? initialPosition}) async {
    if (currentSong == null) return;
    
    _hasScrobbledCurrent = false;
    final streamUrl = subsonicService.getStreamUrl(currentSong!.id, sessionBitRate: _sessionBitRate);
    
    try {
      await _audioPlayer.open(
        Media(streamUrl),
        play: autoPlay,
      );
      if (initialPosition != null && initialPosition.inSeconds > 0) {
        // media_kit: wait for stream duration to be available before seeking
        // Otherwise an immediate seek can throw Invalid argument inside playback core
        await Future.delayed(const Duration(milliseconds: 300)); 
        try {
          await _audioPlayer.seek(initialPosition);
        } catch (_) {}
      }
      // Pre-apply speed and pitch
      try {
        await _audioPlayer.setPitch(_pitch);
      } catch (_) {}
      try {
        await _audioPlayer.setRate(_speed);
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('Error loading audio: $e');
    }
  }

  void _checkScrobble() {
    if (currentSong == null || _duration.inSeconds == 0 || _hasScrobbledCurrent) return;
    
    // Scrobble if 50% reached
    if (_position.inSeconds > (_duration.inSeconds / 2)) {
      _hasScrobbledCurrent = true;
      subsonicService.scrobble(currentSong!.id, DateTime.now().millisecondsSinceEpoch, true).catchError((_) {});
    }
  }

  Future<void> playList(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    _currentAlbum = null;
    
    _position = Duration.zero;
    _duration = Duration(seconds: _queue[_currentIndex].duration);
    notifyListeners();
    
    await _loadCurrentTrack(autoPlay: true);
  }

  void insertNext(Song song) {
    if (_queue.isEmpty) {
      _queue = [song];
      _currentIndex = 0;
      _loadCurrentTrack();
    } else {
      _queue.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }

  void addToQueue(Song song) {
    if (_queue.isEmpty) {
      _queue = [song];
      _currentIndex = 0;
      _loadCurrentTrack();
    } else {
      _queue.add(song);
    }
    notifyListeners();
  }

  Future<void> playSong(Song song, Album? album) async {
    if (currentSong?.id == song.id) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } else {
      // If we clicked a song that is in our current queue, just skip to it
      final int foundIndex = _queue.indexWhere((s) => s.id == song.id);
      if (foundIndex != -1 && album?.id == _currentAlbum?.id) {
        _currentIndex = foundIndex;
      } else {
        // Otherwise, replace queue with this album
        if (album != null && album.songs.isNotEmpty) {
           _queue = album.songs;
           _currentIndex = _queue.indexWhere((s) => s.id == song.id);
           if (_currentIndex == -1) _currentIndex = 0; // fallback
        } else {
           // just play the single song
           _queue = [song];
           _currentIndex = 0;
        }
        _currentAlbum = album;
      }
      
      _position = Duration.zero;
      _duration = Duration(seconds: song.duration);
      notifyListeners();
      
      await _loadCurrentTrack(autoPlay: true);
    }
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipNext() async {
    await _playNext();
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 5) {
      // Restart current track if we are more than 5s in
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
      await _loadCurrentTrack();
    }
  }

  bool _isAutoPlayEnabled = true;
  bool get isAutoPlayEnabled => _isAutoPlayEnabled;

  void toggleAutoPlay(bool value) {
    _isAutoPlayEnabled = value;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle && _currentIndex >= 0 && _currentIndex < _queue.length - 1) {
      final upcoming = _queue.sublist(_currentIndex + 1);
      upcoming.shuffle();
      _queue.replaceRange(_currentIndex + 1, _queue.length, upcoming);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = (_repeatMode + 1) % 3;
    notifyListeners();
  }

  Future<void> _playNext() async {
    if (_repeatMode == 2) {
      await seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      notifyListeners();
      await _loadCurrentTrack();
} else {
      if (_repeatMode == 1 && _queue.isNotEmpty) {
        _currentIndex = 0;
        if (_isShuffle) {
          _queue.shuffle();
        }
        notifyListeners();
        await _loadCurrentTrack();
        return;
      }

      if (_isAutoPlayEnabled && currentSong != null) {
        // Fetch similar songs for "Magic Autoplay"
        final similar = await subsonicService.getSimilarSongs2(currentSong!.id, count: 15);
        final newSongs = similar.where((s) => !_queue.any((q) => q.id == s.id)).toList();
        
        if (newSongs.isNotEmpty) {
          _queue.addAll(newSongs);
          _currentIndex++;
          notifyListeners();
          await _loadCurrentTrack();
          return;
        } else {
          // Fallback to random songs if no similar songs found
          try {
             final randomSongs = await subsonicService.getRandomSongs(size: 10);
             final rNew = randomSongs.where((s) => !_queue.any((q) => q.id == s.id)).toList();
             if (rNew.isNotEmpty) {
                _queue.addAll(rNew);
                _currentIndex++;
                notifyListeners();
                await _loadCurrentTrack();
                return;
             }
          } catch (_) {}
        }
      }

      // End of queue (if autoplay is OFF or we found zero tracks)
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      _position = Duration.zero;
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}


