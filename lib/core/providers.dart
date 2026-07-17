import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:audiotags/audiotags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'models/track.dart';
import 'models/app_playlist.dart';
import 'audio/audio_handler.dart';
import 'api/extractor_service.dart';
import 'api/youtube_dlp_service.dart';
import 'api/music_service.dart';
import 'api/jiosaavn_service.dart';
import 'settings.dart';

import 'db/isar_db.dart';

import 'api/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides singleton offline storage access
final isarDbProvider = Provider<IsarDb>((ref) => IsarDb.instance);

// Watches the live favorite tracks natively from the Isar DB
final favoritesStreamProvider = StreamProvider<List<Track>>((ref) {
  return ref.watch(isarDbProvider).watchFavorites();
});



final ytdlpServiceProvider = Provider<YouTubeDlpService>((ref) => YouTubeDlpService());
final extractorServiceProvider = Provider<ExtractorService>((ref) => ExtractorService());
final jiosaavnServiceProvider = Provider<JioSaavnService>((ref) => JioSaavnService());

// Surfaces playback stream errors to the UI (SnackBar in BottomPlayer)
final saavnErrorProvider = StateProvider<String?>((ref) => null);

// Watches downloaded tracks and auto-fetches external files from the download folder
final downloadsStreamProvider = StreamProvider<List<Track>>((ref) async* {
  final dbStream = ref.watch(isarDbProvider).watchDownloads();
  
  // Cache to prevent parsing ID3 tags every 500ms
  final Map<String, Track> folderCache = {};

  await for (final dbTracks in dbStream) {
    List<Track> folderTracks = [];
    try {
      final prefs = await ref.read(sharedPrefsProvider);
      final customPath = prefs.getString('download_path');
      
      if (kIsWeb) {
        yield dbTracks;
        continue;
      }
      late Directory desiDir;
      if (customPath != null && customPath.isNotEmpty) {
        desiDir = Directory(customPath);
      } else {
        final extDir = await getDownloadsDirectory();
        final docDir = await getApplicationDocumentsDirectory();
        desiDir = Directory('${(extDir ?? docDir).path}/PULSE');
      }

      if (await desiDir.exists()) {
        final entities = desiDir.listSync();
        final currentFilePaths = <String>{};
        
        for (var entity in entities) {
          if (entity is File) {
            final ext = entity.path.split('.').last.toLowerCase();
            if (['mp3', 'm4a', 'opus', 'wav', 'aac', 'flac'].contains(ext)) {
              currentFilePaths.add(entity.path);
              
              // Normalize slashes for Windows compatibility
              final normalizedEntityPath = entity.path.replaceAll('\\', '/');
              final isInDb = dbTracks.any((t) {
                final normalizedLocal = t.localPath?.replaceAll('\\', '/');
                return normalizedLocal == normalizedEntityPath;
              });
              
              if (!isInDb) {
                // If we already parsed this file, use the cached Track
                if (folderCache.containsKey(entity.path)) {
                  folderTracks.add(folderCache[entity.path]!);
                  continue;
                }
                
                final filename = entity.path.split(Platform.pathSeparator).last;
                String title = filename.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                String artist = 'Unknown Artist';

                try {
                  final tag = await AudioTags.read(entity.path);
                  if (tag != null) {
                    if (tag.title != null && tag.title!.isNotEmpty) title = tag.title!;
                    if (tag.trackArtist != null && tag.trackArtist!.isNotEmpty) artist = tag.trackArtist!;
                  }
                } catch (e) {
                  // Ignore tag parsing errors
                }

                // Make a synthetic youtubeId for playback and identity
                final synthId = "file_${entity.path.hashCode}";

                final t = Track()
                  ..id = synthId
                  ..youtubeId = synthId 
                  ..title = title
                  ..artist = artist
                  ..isDownloaded = true
                  ..localPath = entity.path
                  ..trackType = 'downloaded'
                  ..thumbnailUrl = 'file:///${entity.path}';

                folderCache[entity.path] = t;
                folderTracks.add(t);
              }
            }
          }
        }
        
        // Cleanup cache for deleted files
        folderCache.removeWhere((path, _) => !currentFilePaths.contains(path));
      }
    } catch (e) {
      print('Error auto-fetching downloads: $e');
    }

    yield [...dbTracks, ...folderTracks];
  }
});

// Download state provider
final downloadProgressProvider = NotifierProvider<DownloadProgressNotifier, Map<String, double>>(() => DownloadProgressNotifier());

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref.watch(musicServiceProvider), ref.read(isarDbProvider), ref);
});

// The Music Service multiplexer — switches between Extractor (default) and YouTube/yt-dlp
final musicServiceProvider = Provider<MusicService>((ref) {
  final source = ref.watch(settingsProvider).musicSource;
  if (kIsWeb || source == 'jiosaavn') {
    return ref.watch(jiosaavnServiceProvider);
  } else if (source == 'youtube') {
    return ref.watch(ytdlpServiceProvider);
  } else if (source == 'jiosaavn') {
    return ref.watch(jiosaavnServiceProvider);
  }
  // 'extractor' is the default — mirrors the extractor pub package on Windows
  return ref.watch(extractorServiceProvider);
});

// Tracks Only Search
final searchResultsProvider = FutureProvider.family<List<Track>, String>((ref, query) async {
  if (query.isEmpty) return ref.read(sampleTracksProvider);
  if (query.startsWith('http') || query.startsWith('www.')) {
     return await ref.read(ytdlpServiceProvider).search(query);
  }
  final service = ref.watch(musicServiceProvider);
  return await service.search(query);
});

// Unified Search Result Object
class UnifiedSearchResults {
  final List<Track> tracks;
  final List<AppPlaylist> playlists;
  final List<AppPlaylist> podcasts;
  final List<Track> episodes;
  UnifiedSearchResults({required this.tracks, required this.playlists, this.podcasts = const [], this.episodes = const []});
}

// Multi-type Search Provider
final searchResultsUnifiedProvider = FutureProvider.family<UnifiedSearchResults, String>((ref, query) async {
  if (query.isEmpty) return UnifiedSearchResults(tracks: [], playlists: []);
  
  final service = ref.watch(musicServiceProvider);
  final filter = ref.watch(searchFilterProvider);
  
  if (filter == 'podcasts') {
     final yt = ref.watch(ytdlpServiceProvider);
     final results = await Future.wait([
       yt.searchPodcasts(query),
       yt.searchEpisodes(query),
     ]);
     return UnifiedSearchResults(
       tracks: [], 
       playlists: [], 
       podcasts: results[0] as List<AppPlaylist>, 
       episodes: results[1] as List<Track>
     );
  }
  
  // Fetch in parallel for speed
  final results = await Future.wait([
    service.search(query),
    service.searchPlaylists(query),
  ]);

  return UnifiedSearchResults(
    tracks: results[0] as List<Track>,
    playlists: results[1] as List<AppPlaylist>,
  );
});

// Playlist Search resolver
final playlistSearchResultsProvider = FutureProvider.family<List<AppPlaylist>, String>((ref, query) async {
  return await ref.watch(musicServiceProvider).searchPlaylists(query);
});

// Dynamic Recommendation Aggregator mapped tightly to historical usage metrics natively.
final recommendationsProvider = FutureProvider<List<Track>>((ref) async {
  final keywords = ref.read(isarDbProvider).getRecommendedKeywords();
  final api = ref.watch(musicServiceProvider);
  final List<Track> cluster = [];
  for (var k in keywords) {
    try { cluster.addAll(await api.search(k)); } catch(e) {}
  }
  cluster.shuffle();
  return cluster.take(40).toList();
});

// Provides top native trending artists from YouTube Music safely.
final topArtistsProvider = FutureProvider<List<dynamic>>((ref) async {
  final yt = await YTMusic.create();
  final settings = ref.watch(settingsProvider);
  
  List<dynamic> trending = [];
  try {
     trending = await yt.search("Top trending artists Hindi", filter: SearchFilter.artists);
  } catch(e) {}

  final List<dynamic> custom = [];
  for (var name in settings.customArtists) {
     try {
       final res = await yt.search(name, filter: SearchFilter.artists);
       if (res.isNotEmpty) {
         // Add a flag so we can identify custom artists if needed
         final artist = res.first;
         artist['isCustom'] = true;
         custom.add(artist);
       }
     } catch(e) {}
  }

  // Deduplicate and merge
  final seen = <String>{};
  final result = <dynamic>[];
  
  for (var a in [...custom, ...trending]) {
    final name = (a['name'] ?? a['artist'] ?? '').toString();
    if (name.isNotEmpty && !seen.contains(name)) {
      seen.add(name);
      result.add(a);
    }
  }

  return result;
});

// Provides the current active navigation index
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(() => NavIndexNotifier());

// Provides dynamic search text globally
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => "";

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

// Search filter state ('all', 'songs', 'playlists')
class SearchFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) {
    state = filter;
  }
}

final searchFilterProvider = NotifierProvider<SearchFilterNotifier, String>(() => SearchFilterNotifier());

// Suggestions provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return await ref.watch(musicServiceProvider).getSearchSuggestions(query);
});

// Provides the singleton audio handler
final audioHandlerProvider = Provider<DesiAudioHandler>((ref) {
  throw UnimplementedError(); // Initialized in main.dart
});

// Provides dynamic sequential playback and history routing
class QueueNotifier extends Notifier<List<Track>> {
  int currentIndex = 0;
  String repeatMode = 'none'; // none, all, one
  bool isShuffle = false;
  final Map<String, String> _urlCache = {};

  @override
  List<Track> build() {
    ref.read(audioHandlerProvider).onCompleted = () {
      playNext();
    };
    return [];
  }
  
  void toggleShuffle() {
    isShuffle = !isShuffle;
    ref.notifyListeners();
  }

  void nextRepeatMode() {
    if (repeatMode == 'none') repeatMode = 'all';
    else if (repeatMode == 'all') repeatMode = 'one';
    else repeatMode = 'none';
    ref.notifyListeners();
  }

  Future<void> playAll(List<Track> tracks, {int startIndex = 0}) async {
    state = tracks;
    currentIndex = startIndex;
    await _playCurrent();
    _populateSimilars();
  }

  Future<void> _populateSimilars() async {
    if (state.length > 5) return;
    final track = ref.read(currentTrackProvider);
    if (track == null) return;

    try {
      final MusicService api = track.trackType == 'youtube'
          ? ref.read(ytdlpServiceProvider)
          : ref.read(extractorServiceProvider);
          
      var similar = await api.getSimilarTracks(track.youtubeId, artistName: track.artist, currentTitle: track.title);
      if (similar.isNotEmpty) {
        final existingIds = state.map((e) => e.youtubeId).toSet();
        similar = similar
            .where((t) => !existingIds.contains(t.youtubeId))
            .take(15)
            .toList();
        
        if (similar.isNotEmpty) {
          state = [...state, ...similar];
          ref.notifyListeners();
        }
      }
    } catch (e) {
      print('Auto-populate suggestions failed: $e');
    }
  }

  Future<void> _playCurrent() async {
    if (currentIndex < 0 || currentIndex >= state.length) return;
    final track = state[currentIndex];
    
    // Instantly reset the playback engine so the old song stops bleeding over
    await ref.read(audioHandlerProvider).stop();
    
    ref.read(isarDbProvider).logHistory(track);
    ref.read(currentTrackProvider.notifier).setTrack(track);

    String? streamUrl = _urlCache[track.youtubeId];

    if (streamUrl == null) {
      // 1. Check local DB
      final localMeta = ref.read(isarDbProvider).getDownloadedTrack(track.youtubeId);
      if (localMeta != null && localMeta.localPath != null && localMeta.localPath!.isNotEmpty) {
        if (await File(localMeta.localPath!).exists()) {
          streamUrl = localMeta.localPath;
        }
      }
    }

    if (streamUrl == null) {
      if (track.trackType == 'podcast') {
        // For podcasts, we inject the raw .mp3 feed URL straight into youtubeId.
        streamUrl = track.youtubeId;
      } else {
        try {
          final MusicService api = track.trackType == 'youtube'
              ? ref.read(ytdlpServiceProvider)
              : ref.read(extractorServiceProvider);
          streamUrl = await api.getStreamUrl(track.youtubeId);
          if (streamUrl != null) _urlCache[track.youtubeId] = streamUrl;
        } catch (e) {
          print('Direct stream fetch failed: $e');
        }
      }
    }

    // Fallback: search by title if still no URL (cross-service recovery)
    if (streamUrl == null) {
      final query = "${track.title} ${track.artist}".trim();
      final api = ref.read(musicServiceProvider); // Use global active for fallback search
      try {
        final results = await api.search(query);
        if (results.isNotEmpty) {
          streamUrl = await api.getStreamUrl(results.first.youtubeId);
        }
      } catch (e) {}
    }
    
    if (streamUrl != null) {
      ref.read(saavnErrorProvider.notifier).state = null; // clear any previous error
      await ref.read(audioHandlerProvider).playTrack(track, streamUrl);
      _preFetchNext();
    } else {
      // Surface error to UI
      ref.read(saavnErrorProvider.notifier).state =
          'Could not load "${track.title}" — skipping to next track.';
      playNext();
    }
  }

  Future<void> preWarmLink(Track track) async {
    if (_urlCache.containsKey(track.youtubeId)) return;
    try {
      final MusicService api = track.trackType == 'youtube'
          ? ref.read(ytdlpServiceProvider)
          : ref.read(extractorServiceProvider);
      final url = await api.getStreamUrl(track.youtubeId);
      if (url != null) {
        _urlCache[track.youtubeId] = url;
        print('[Extractor] Pre-warmed link for: ${track.title}');
      }
    } catch (e) {}
  }

  Future<void> _preFetchNext() async {
    final nextIdx = currentIndex + 1;
    if (nextIdx >= state.length) return;
    final nextTrack = state[nextIdx];
    if (_urlCache.containsKey(nextTrack.youtubeId)) return;

    if (nextTrack.trackType == 'podcast') {
       _urlCache[nextTrack.youtubeId] = nextTrack.youtubeId;
       return;
    }

    try {
      final MusicService api = nextTrack.trackType == 'youtube'
          ? ref.read(ytdlpServiceProvider)
          : ref.read(extractorServiceProvider);
      final url = await api.getStreamUrl(nextTrack.youtubeId);
      if (url != null) _urlCache[nextTrack.youtubeId] = url;
    } catch (e) {}
  }

  Future<void> playNext() async {
    if (repeatMode == 'one') {
      await _playCurrent();
      return;
    }
    if (isShuffle && state.isNotEmpty) {
      currentIndex = (currentIndex + 1 + (DateTime.now().millisecond % state.length)) % state.length;
      await _playCurrent();
      return;
    }

    if (currentIndex < state.length - 1) {
      currentIndex++;
      await _playCurrent();
    } else if (repeatMode == 'all' && state.isNotEmpty) {
      currentIndex = 0;
      await _playCurrent();
    } else {
      // Auto-load similar on queue end
      final lastTrack = state.isNotEmpty ? state.last : null;
      if (lastTrack != null) {
        try {
          final api = lastTrack.trackType == 'youtube' ? ref.read(ytdlpServiceProvider) : ref.read(extractorServiceProvider);
          final similar = await api.getSimilarTracks(lastTrack.youtubeId, artistName: lastTrack.artist, currentTitle: lastTrack.title);
          if (similar.isNotEmpty) {
            state = [...state, ...similar];
            currentIndex++;
            await _playCurrent();
            return;
          }
        } catch(e) {}
      }
      currentIndex = -1;
      ref.notifyListeners();
    }
  }

  void playPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      _playCurrent();
    } else if (repeatMode == 'all' && state.isNotEmpty) {
      currentIndex = state.length - 1;
      _playCurrent();
    }
  }

  void insertNext(Track track) {
    final newList = List<Track>.from(state);
    newList.insert(currentIndex + 1, track);
    state = newList;
  }

  void enqueue(Track track) {
    state = [...state, track];
  }

  void jumpTo(int index) {
    if (index >= 0 && index < state.length) {
      currentIndex = index;
      _playCurrent();
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < state.length) {
      final newList = List<Track>.from(state);
      newList.removeAt(index);
      state = newList;
      if (currentIndex == index) {
        if (state.isNotEmpty) {
          currentIndex = currentIndex % state.length;
          _playCurrent();
        } else {
          currentIndex = -1;
        }
      } else if (currentIndex > index) {
        currentIndex--;
      }
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.removeAt(oldIndex);
    state.insert(newIndex, item);
    state = List<Track>.from(state); // trigger state update

    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (currentIndex > oldIndex && currentIndex <= newIndex) {
      currentIndex--;
    } else if (currentIndex < oldIndex && currentIndex >= newIndex) {
      currentIndex++;
    }
  }

  Future<void> startRadio(Track track) async {
     try {
       final api = track.trackType == 'youtube' ? ref.read(ytdlpServiceProvider) : ref.read(extractorServiceProvider);
       final similar = await api.getSimilarTracks(track.youtubeId, artistName: track.artist, currentTitle: track.title);
       state = [track, ...similar];
       currentIndex = 0;
       await _playCurrent();
     } catch(e) {
       playAll([track]);
     }
  }
}final queueProvider = NotifierProvider<QueueNotifier, List<Track>>(() => QueueNotifier());

// Provides a list of sample tracks (with real thumbnails & audio)
final sampleTracksProvider = Provider<List<Track>>((ref) {
  return [
    Track()
      ..id = '1'
      ..title = 'Lofi Beats - Chill & Relax'
      ..artist = 'Desi Vibes'
      ..thumbnailUrl = 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400&auto=format&fit=crop'
      ..durationMs = 200000
      ..youtubeId = '1'
      ..localPath = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Free sample mp3
    Track()
      ..id = '2'
      ..title = 'Ghazal Evening - Live'
      ..artist = 'Ustad Ali'
      ..thumbnailUrl = 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=400&auto=format&fit=crop'
      ..durationMs = 300000
      ..youtubeId = '2'
      ..localPath = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  ];
});

// Currently playing track state
class CurrentTrackNotifier extends Notifier<Track?> {
  @override
  Track? build() => null;

  void setTrack(Track track) {
    state = track;
  }
}

final currentTrackProvider = NotifierProvider<CurrentTrackNotifier, Track?>(() {
  return CurrentTrackNotifier();
});

// Playback state (playing, buffering)
final playbackStateProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.stream.playing;
});

final bufferingStateProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.stream.buffering;
});

final positionStateProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.stream.position;
});

final durationStateProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.stream.duration;
});

final volumeStateProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.stream.volume;
});

// Search History Provider
final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(() => SearchHistoryNotifier());

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'search_history';
  late SharedPreferences _prefs;

  @override
  List<String> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs.getStringList(_key) ?? [];
  }

  void add(String query) {
    if (query.trim().isEmpty) return;
    final normalized = query.trim();
    if (state.contains(normalized)) {
      state = [normalized, ...state.where((e) => e != normalized)];
    } else {
      state = [normalized, ...state];
    }
    if (state.length > 20) state = state.sublist(0, 20);
    _prefs.setStringList(_key, state);
  }

  void remove(String query) {
    state = state.where((e) => e != query).toList();
    _prefs.setStringList(_key, state);
  }

  void clear() {
    state = [];
    _prefs.setStringList(_key, state);
  }
}

// Mini Player State
final isMiniPlayerProvider = StateProvider<bool>((ref) => false);
