import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../data/demo_seed.dart';
import '../models/festival_event.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../services/community/community_service.dart';
import '../services/discovery/discovery_engine.dart';
import '../services/downloads/download_manager.dart';
import '../services/library/library_repository.dart';
import '../services/playback/playback_controller.dart';

final currentDestinationProvider = StateProvider<AppDestination>(
  (Ref ref) => AppDestination.home,
);

final searchQueryProvider = StateProvider<String>((Ref ref) => '');

final selectedLanguageProvider = StateProvider<String>((Ref ref) => 'Hindi');

final festivalModeProvider = StateProvider<bool>((Ref ref) => true);

final rightPanelTabProvider = StateProvider<int>((Ref ref) => 0);

final lyricsTranslationProvider = StateProvider<bool>((Ref ref) => false);

final themeModeProvider = StateProvider<ThemeMode>((Ref ref) => ThemeMode.dark);

final themePackProvider = StateProvider<FestivalThemePack>(
  (Ref ref) => AppTheme.packs[AppTheme.autoPackIndexForDate(DateTime.now())],
);

final libraryRepositoryProvider = ChangeNotifierProvider<LibraryRepository>(
  (Ref ref) => LibraryRepository(),
);

final communityServiceProvider = ChangeNotifierProvider<CommunityService>(
  (Ref ref) => CommunityService(),
);

final discoveryEngineProvider = Provider<DiscoveryEngine>((Ref ref) {
  return const DiscoveryEngine();
});

final downloadManagerProvider = ChangeNotifierProvider<DownloadManager>((
  Ref ref,
) {
  return DownloadManager(initialTasks: DemoSeed.downloadTasks);
});

final catalogSongsProvider = Provider<List<Song>>((Ref ref) => DemoSeed.songs);

final festivalEventsProvider = Provider<List<FestivalEvent>>(
  (Ref ref) => DemoSeed.buildFestivals(DateTime.now()),
);

final playbackControllerProvider = ChangeNotifierProvider<PlaybackController>((
  Ref ref,
) {
  final library = ref.watch(libraryRepositoryProvider);
  final discovery = ref.watch(discoveryEngineProvider);
  final controller = PlaybackController(
    libraryRepository: library,
    discoveryEngine: discovery,
    catalog: DemoSeed.songs,
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final filteredSongsProvider = Provider<List<Song>>((Ref ref) {
  final engine = ref.watch(discoveryEngineProvider);
  final songs = ref.watch(catalogSongsProvider);
  final query = ref.watch(searchQueryProvider);
  final language = ref.watch(selectedLanguageProvider);
  return engine.searchSongs(
    query,
    songs,
    language: language == 'All' ? null : language,
  );
});
