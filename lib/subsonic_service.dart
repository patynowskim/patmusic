import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subsonic_api/subsonic_api.dart';
import 'settings_service.dart';

class SubsonicPlaylist {
  final String id;
  final String name;
  final String owner;
  final int songCount;
  final int duration;
  final String created;
  final String coverArt;
  List<Song> songs;

  SubsonicPlaylist({
    required this.id,
    required this.name,
    required this.owner,
    required this.songCount,
    required this.duration,
    required this.created,
    required this.coverArt,
    this.songs = const [],
  });
}

class SubsonicService {
  final SettingsService settings;

  SubsonicService(this.settings);

  String get _baseUrl => settings.endpoint;
  String get _username => settings.username;
  String get _password => settings.password;

  Future<List<Album>> getAlbumList2({required String type, int? size}) async {
    final url = Uri.parse(
      '$_baseUrl/rest/getAlbumList2.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&type=$type&size=${size ?? 20}',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'failed') {
      throw Exception(subsonic['error']['message'] ?? 'Subsonic request failed');
    }

    final albumList = subsonic['albumList2'];
    if (albumList == null || albumList['album'] == null) {
      return [];
    }

    return (albumList['album'] as List).map((json) {
      return Album(
        id: json['id'],
        name: json['name'],
        coverArt: json['coverArt'],
        songCount: json['songCount'] ?? 0,
        created: json['created'] ?? '',
        duration: json['duration'] ?? 0,
        artist: json['artist'] ?? '',
        artistId: json['artistId'] ?? '',
        songs: [],
      );
    }).toList();
  }

  Future<List<Album>> getRecentlyAddedAlbums({int? size}) async {
    return getAlbumList2(type: 'newest', size: size);
  }

  Future<Album> getAlbum(String id) async {
    final url = Uri.parse(
      '$_baseUrl/rest/getAlbum.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to connect to server: ${response.statusCode}');
    }
    
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'failed') {
      throw Exception(subsonic['error']['message'] ?? 'Subsonic request failed');
    }

    final albumData = subsonic['album'];
    if (albumData == null) {
      throw Exception('Album not found');
    }

    final songList = albumData['song'] as List? ?? [];
    final songs = songList.map((s) {
      return Song(
        id: s['id'],
        parent: s['parent'] ?? '',
        title: s['title'] ?? '',
        album: s['album'] ?? '',
        artist: s['artist'] ?? '',
        isDir: s['isDir'] ?? false,
        coverArt: s['coverArt'] ?? '',
        created: s['created'] ?? '',
        duration: s['duration'] ?? 0,
        bitRate: s['bitRate'] ?? 0,
        size: s['size'] ?? 0,
        suffix: s['suffix'] ?? '',
        contentType: s['contentType'] ?? '',
        isVideo: s['isVideo'] ?? false,
        path: s['path'] ?? '',
        albumId: s['albumId'] ?? '',
        artistId: s['artistId'] ?? '',
        type: s['type'] ?? '',
        played: s['played'] ?? '',
      );
    }).toList();

    return Album(
      id: albumData['id'],
      name: albumData['name'] ?? '',
      coverArt: albumData['coverArt'] ?? '',
      songCount: albumData['songCount'] ?? 0,
      created: albumData['created'] ?? '',
      duration: albumData['duration'] ?? 0,
      artist: albumData['artist'] ?? '',
      artistId: albumData['artistId'] ?? '',
      songs: songs,
    );
  }

  Future<List<Song>> getRandomSongs({int? size}) async {
    final url = Uri.parse(
      '$_baseUrl/rest/getRandomSongs.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&size=${size ?? 20}',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'failed') {
      throw Exception(subsonic['error']['message'] ?? 'Subsonic request failed');
    }

    final randomSongs = subsonic['randomSongs'];
    if (randomSongs == null || randomSongs['song'] == null) {
      return [];
    }

    return (randomSongs['song'] as List).map((s) => _mapSong(s)).toList();
  }

  Song _mapSong(Map<String, dynamic> s) {
    return Song(
      id: s['id'],
      parent: s['parent'] ?? '',
      title: s['title'] ?? '',
      album: s['album'] ?? '',
      artist: s['artist'] ?? '',
      isDir: s['isDir'] ?? false,
      coverArt: s['coverArt'] ?? '',
      created: s['created'] ?? '',
      duration: s['duration'] ?? 0,
      bitRate: s['bitRate'] ?? 0,
      size: s['size'] ?? 0,
      suffix: s['suffix'] ?? '',
      contentType: s['contentType'] ?? '',
      isVideo: s['isVideo'] ?? false,
      path: s['path'] ?? '',
      albumId: s['albumId'] ?? '',
      artistId: s['artistId'] ?? '',
      type: s['type'] ?? '',
      played: s['played'] ?? '',
    );
  }

  Future<List<dynamic>> getArtists() async {
    final url = Uri.parse(
      '$_baseUrl/rest/getArtists.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'failed') {
      throw Exception(subsonic['error']['message'] ?? 'Subsonic request failed');
    }

    final artistsData = subsonic['artists'];
    if (artistsData == null || artistsData['index'] == null) {
      return [];
    }
    
    List<dynamic> allArtists = [];
    for (var index in artistsData['index']) {
      if (index['artist'] != null) {
        allArtists.addAll(index['artist']);
      }
    }

    return allArtists;
  }

  Future<Map<String, dynamic>> getArtist(String id) async {
    final url = Uri.parse('$_baseUrl/rest/getArtist.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id');
    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'failed') {
      throw Exception(subsonic['error']['message'] ?? 'Subsonic request failed');
    }

    return subsonic['artist'];
  }

  Future<void> createPlaylist(String name, {String? songId}) async {
    String urlStr = '$_baseUrl/rest/createPlaylist.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&name=${Uri.encodeComponent(name)}';
    if (songId != null) {
      urlStr += '&songId=$songId';
    }
    await http.get(Uri.parse(urlStr));
  }

  Future<void> updatePlaylist(String playlistId, {List<String>? songIdsToAdd, List<int>? songIndexesToRemove}) async {
    String urlStr = '$_baseUrl/rest/updatePlaylist.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&playlistId=$playlistId';
    if (songIdsToAdd != null) {
      for (final id in songIdsToAdd) {
        urlStr += '&songIdToAdd=$id';
      }
    }
    if (songIndexesToRemove != null) {
      for (final idx in songIndexesToRemove) {
        urlStr += '&songIndexToRemove=$idx';
      }
    }
    await http.get(Uri.parse(urlStr));
  }

  String getStreamUrl(String id, {int? sessionBitRate}) {
    String url = '$_baseUrl/rest/stream.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&id=$id';
    
    final bitRateToUse = sessionBitRate ?? settings.maxBitRate;
    if (bitRateToUse > 0) {
      url += '&maxBitRate=$bitRateToUse';
    }
    return url;
  }

  Future<List<Song>> getSimilarSongs2(String id, {int count = 50}) async {
    final url = Uri.parse('$_baseUrl/rest/getSimilarSongs2.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id&count=$count');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      final data = json.decode(response.body);
      final subsonic = data['subsonic-response'];
      if (subsonic['status'] == 'ok' && subsonic['similarSongs2'] != null && subsonic['similarSongs2']['song'] != null) {
        return (subsonic['similarSongs2']['song'] as List).map((s) => _mapSong(s)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<SubsonicPlaylist>> getPlaylists() async {
    final url = Uri.parse('$_baseUrl/rest/getPlaylists.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json');
    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'ok' && subsonic['playlists'] != null && subsonic['playlists']['playlist'] != null) {
      return (subsonic['playlists']['playlist'] as List).map((p) {
        return SubsonicPlaylist(
          id: p['id'],
          name: p['name'] ?? 'Unknown',
          owner: p['owner'] ?? '',
          songCount: p['songCount'] ?? 0,
          duration: p['duration'] ?? 0,
          created: p['created'] ?? '',
          coverArt: p['coverArt'] ?? '',
        );
      }).toList();
    }
    return [];
  }

  Future<SubsonicPlaylist?> getPlaylist(String id) async {
    final url = Uri.parse('$_baseUrl/rest/getPlaylist.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id');
    final response = await http.get(url);
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];

    if (subsonic['status'] == 'ok' && subsonic['playlist'] != null) {
      final p = subsonic['playlist'];
      final pl = SubsonicPlaylist(
        id: p['id'],
        name: p['name'] ?? 'Unknown',
        owner: p['owner'] ?? '',
        songCount: p['songCount'] ?? 0,
        duration: p['duration'] ?? 0,
        created: p['created'] ?? '',
        coverArt: p['coverArt'] ?? '',
      );
      if (p['entry'] != null) {
        pl.songs = (p['entry'] as List).map((s) => _mapSong(s)).toList();
      }
      return pl;
    }
    return null;
  }

  Future<List<Song>> getStarredSongs() async {
    // We treat starred items as a playlist
    final url = Uri.parse('$_baseUrl/rest/getStarred.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      final subsonic = data['subsonic-response'];
      if (subsonic['status'] == 'ok' && subsonic['starred'] != null && subsonic['starred']['song'] != null) {
        return (subsonic['starred']['song'] as List).map((s) => _mapSong(s)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getLyrics(String artist, String title, String songId) async {
    // Try OpenSubsonic getLyricsBySongId first
    try {
      final url = Uri.parse('$_baseUrl/rest/getLyricsBySongId.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$songId');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subsonic = data['subsonic-response'];
        if (subsonic['status'] == 'ok' && subsonic['lyricsList'] != null) {
          final struct = subsonic['lyricsList']['structuredLyrics'];
          if (struct != null && struct.isNotEmpty) {
            final lines = struct[0]['line'];
            if (lines != null) {
              return {'type': 'structured', 'data': lines}; // List of {start: ms, value: "text"}
            }
          }
        }
      }
    } catch (_) {}

    // Fallback to legacy getLyrics
    final url = Uri.parse(
      '$_baseUrl/rest/getLyrics.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      final data = json.decode(response.body);
      final subsonic = data['subsonic-response'];
      if (subsonic['status'] == 'ok' && subsonic['lyricsList'] != null && subsonic['lyricsList']['structuredLyrics'] != null) {
        final lyrics = subsonic['lyricsList']['structuredLyrics'];
        if (lyrics != null && lyrics.isNotEmpty) {
           final lines = lyrics[0]['line'];
           if (lines != null) {
             return {'type': 'structured', 'data': lines};
           }
        }
      }
      if (subsonic['status'] == 'ok' && subsonic['lyrics'] != null) {
         return {'type': 'plain', 'data': subsonic['lyrics']['value']};
      }
    } catch (_) {}
    return null;
  }

  Future<void> star(String id) async {
    final url = Uri.parse('$_baseUrl/rest/star.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id');
    await http.get(url);
  }

  Future<void> unstar(String id) async {
    final url = Uri.parse('$_baseUrl/rest/unstar.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id');
    await http.get(url);
  }

  Future<bool> checkStarred(String id) async {
    final url = Uri.parse('$_baseUrl/rest/getSong.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      final subsonic = data['subsonic-response'];
      if (subsonic['status'] == 'ok' && subsonic['song'] != null) {
        return subsonic['song']['starred'] != null;
      }
    } catch (_) {}
    return false;
  }

  Future<void> scrobble(String id, int timeMsec, bool submission) async {
    final url = Uri.parse('$_baseUrl/rest/scrobble.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&id=$id&time=$timeMsec&submission=$submission');
    await http.get(url);
  }

  Future<Map<String, dynamic>> search3(String query) async {
    final url = Uri.parse('$_baseUrl/rest/search3.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&f=json&query=${Uri.encodeComponent(query)}');
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Search failed');
    final data = json.decode(response.body);
    final subsonic = data['subsonic-response'];
    if (subsonic['status'] == 'failed') throw Exception('Search failed');
    return subsonic['searchResult3'] ?? {};
  }

  String getCoverArtUrl(String id, {int? size}) {
    String url = '$_baseUrl/rest/getCoverArt.view?u=$_username&p=$_password&v=1.16.1&c=PatMusic&id=$id';
    if (size != null) {
      url += '&size=$size';
    }
    return url;
  }
}
