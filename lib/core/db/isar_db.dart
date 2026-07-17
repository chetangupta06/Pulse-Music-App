import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import '../models/app_playlist.dart';

class IsarDb {
  static final IsarDb instance = IsarDb._internal();
  IsarDb._internal();

  late File _file;
  late File _playlistFile;
  List<Track> _cache = [];
  List<AppPlaylist> _playlistCache = [];

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/desi_db.json');
    _playlistFile = File('${dir.path}/desi_db_playlists.json');
    _file = File('${dir.path}/desi_db.json');
    if (await _file.exists()) {
      final text = await _file.readAsString();
      if (text.isNotEmpty) {
        try {
          final List decoded = jsonDecode(text);
          _cache = decoded.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          print('DB parse error: $e');
          _cache = [];
        }
      }
    }
    
    if (await _playlistFile.exists()) {
      final text = await _playlistFile.readAsString();
      if (text.isNotEmpty) {
        try {
          final List decoded = jsonDecode(text);
          _playlistCache = decoded.map((e) => AppPlaylist.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          _playlistCache = [];
        }
      }
    }
    print('IsarDb initialized with ${_cache.length} tracks and ${_playlistCache.length} playlists.');
    
    // One-time cleanup: remove duplicate non-history entries
    final seen = <String>{};
    final cleaned = <Track>[];
    for (final t in _cache) {
      if (t.trackType == 'history') {
        cleaned.add(t); // history entries are fine to duplicate
      } else {
        if (!seen.contains(t.youtubeId)) {
          seen.add(t.youtubeId);
          cleaned.add(t);
        }
      }
    }
    if (cleaned.length != _cache.length) {
      print('DB cleanup: removed ${_cache.length - cleaned.length} duplicate entries');
      _cache = cleaned;
      await _write();
    }
  }

  Future<void> deleteTrackDownload(String id) async {
    final idx = _cache.indexWhere((t) => t.youtubeId == id);
    if (idx != -1) {
      final track = _cache[idx];
      if (track.localPath != null && track.localPath!.isNotEmpty) {
        try {
          final file = File(track.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print("Error deleting music file: $e");
        }
      }
      track.isDownloaded = false;
      track.localPath = null;
      await _write();
    }
  }

  Future<void> _write() async {
    await _file.writeAsString(jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  Future<void> _writePlaylists() async {
    await _playlistFile.writeAsString(jsonEncode(_playlistCache.map((e) => e.toJson()).toList()));
  }

  // --- PLAYLIST LOGIC ---
  Future<void> savePlaylist(AppPlaylist p) async {
    final idx = _playlistCache.indexWhere((x) => x.id == p.id);
    if (idx != -1) {
      _playlistCache[idx] = p;
    } else {
      _playlistCache.add(p);
    }
    await _writePlaylists();
  }

  Future<void> removePlaylist(String id) async {
    _playlistCache.removeWhere((x) => x.id == id);
    await _writePlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final idx = _playlistCache.indexWhere((x) => x.id == id);
    if (idx != -1) {
      _playlistCache[idx].title = newName;
      await _writePlaylists();
    }
  }

  bool isPlaylistSaved(String id) {
    return _playlistCache.any((x) => x.id == id);
  }

  Future<void> createPlaylist(String title) async {
    final p = AppPlaylist()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..type = 'user'
      ..tracks = [];
    _playlistCache.add(p);
    await _writePlaylists();
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final idx = _playlistCache.indexWhere((x) => x.id == playlistId);
    if (idx != -1) {
      final p = _playlistCache[idx];
      p.tracks ??= [];
      if (!p.tracks!.any((t) => t.youtubeId == track.youtubeId)) {
        p.tracks!.add(track);
        await _writePlaylists();
      }
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final idx = _playlistCache.indexWhere((x) => x.id == playlistId);
    if (idx != -1) {
      final p = _playlistCache[idx];
      p.tracks?.removeWhere((t) => t.youtubeId == trackId);
      await _writePlaylists();
    }
  }

  Stream<List<AppPlaylist>> watchSavedPlaylists() async* {
    while (true) {
      yield List.from(_playlistCache);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  // --- HISTORY LOGIC ---
  Future<void> logHistory(Track track) async {
    // Keep a clone for history uniquely tracking usage natively instead of overwriting favorite states
    final historyTrack = Track.fromJson(track.toJson())..trackType = 'history';
    _cache.removeWhere((t) => t.youtubeId == track.youtubeId && t.trackType == 'history');
    _cache.insert(0, historyTrack);
    if (_cache.where((t) => t.trackType == 'history').length > 50) {
      _cache.removeLast(); // Keep size bounded
    }
    await _write();
  }

  List<String> getPodcastRecommendations() {
    final histories = _cache.where((t) => t.trackType == 'history').toList();
    final podcastHistories = histories.where((t) => t.trackType == 'podcast' || t.title.toLowerCase().contains('podcast') || t.artist.toLowerCase().contains('podcast')).toList();
    
    if (podcastHistories.isEmpty) {
      return ["Self improvement podcast", "Comedy podcast", "Storytelling podcast"];
    }

    final Map<String, int> counts = {};
    for (var h in podcastHistories) {
       final artist = h.artist.split(',').first.trim();
       if (artist.isNotEmpty && artist != 'Unknown' && artist != 'Podcast Episode') {
          counts[artist] = (counts[artist] ?? 0) + 1;
       }
    }
    
    if (counts.isEmpty) return ["Popular podcast", "Trending podcasts"];
    
    final sorted = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final topArtists = sorted.take(3).toList();
    
    final List<String> queries = [];
    for (int i = 0; i < topArtists.length; i++) {
       queries.add("${topArtists[i].key} podcast");
    }
    return queries;
  }

  List<String> getRecommendedKeywords() {
    // Pull the artists from recent history to build dynamic recommendations
    final histories = _cache.where((t) => t.trackType == 'history').take(50).toList();
    if (histories.isEmpty) return ["Arijit Singh Latest Hits", "Bollywood Top Songs 2026", "Viral Hindi Songs"];
    
    final Map<String, int> counts = {};
    for (var h in histories) {
       final artist = h.artist.split(',').first.trim();
       if (artist.isNotEmpty && artist != 'Unknown' && !artist.contains('YouTube Record')) {
          counts[artist] = (counts[artist] ?? 0) + 1;
       }
    }
    
    if (counts.isEmpty) return ["Arijit Singh Latest Hits", "Bollywood Top Songs 2026"];
    
    final sorted = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final topArtists = sorted.take(5).toList();
    
    final List<String> queries = [];
    final suffixes = ["Best of", "Latest hits", "Top songs"];
    for (int i = 0; i < topArtists.length; i++) {
       final artist = topArtists[i].key;
       final prefix = suffixes[i % suffixes.length];
       if (prefix == "Best of") {
           queries.add("Best of $artist");
       } else {
           queries.add("$artist $prefix");
       }
    }
    
    // Add a generic booster
    queries.add("Bollywood Hits");
    
    return queries;
  }

  Future<void> saveTrack(Track track) async {
    final idx = _cache.indexWhere((t) => t.youtubeId == track.youtubeId);
    if (idx != -1) {
      _cache[idx] = track;
    } else {
      _cache.add(track);
    }
    await _write();
  }

  Future<void> toggleFavorite(Track track) async {
    // Check if already favorited (ignore history entries)
    final favIdx = _cache.indexWhere((t) => t.youtubeId == track.youtubeId && t.trackType == 'favorite');
    
    if (favIdx != -1) {
      // UNFAVORITING — if downloaded, keep entry but revert trackType; otherwise remove
      if (_cache[favIdx].isDownloaded) {
        _cache[favIdx].trackType = 'downloaded';
      } else {
        _cache.removeAt(favIdx);
      }
    } else {
      // FAVORITING — find any existing non-history entry and update it in-place
      final existingIdx = _cache.indexWhere((t) => t.youtubeId == track.youtubeId && t.trackType != 'history');
      
      if (existingIdx != -1) {
        // Update existing entry in-place (keeps download fields intact, no duplication)
        _cache[existingIdx].trackType = 'favorite';
      } else {
        // No existing entry — add a fresh one
        final newTrack = Track.fromJson(track.toJson());
        newTrack.trackType = 'favorite';
        _cache.add(newTrack);
      }
    }
    await _write();
  }

  Stream<List<Track>> watchFavorites() async* {
    while (true) {
      yield _cache.where((t) => t.trackType == 'favorite').toList();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Stream<List<Track>> watchDownloads() async* {
    while (true) {
      yield _cache.where((t) => t.trackType != 'history' && (t.isDownloaded || (t.localPath != null && t.localPath!.isNotEmpty))).toList();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Track? getDownloadedTrack(String youtubeId) {
    for (final t in _cache) {
      if (t.youtubeId == youtubeId && t.trackType != 'history' && (t.isDownloaded || (t.localPath != null && t.localPath!.isNotEmpty))) {
        return t;
      }
    }
    return null;
  }
}
