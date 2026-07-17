import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialized in main');
});

class AppSettings {
  final String? userName;
  final String? profileImagePath;
  final String? downloadPath;
  final String musicSource;
  final List<String> activeHomeSections;
  final String themeMode;
  final List<String> customArtists; // List of artist names to pin
  
  final List<String> podcastActiveSections;
  final String podcastLanguage;
  final List<String> customPodcasters;
  
  const AppSettings({
    this.userName,
    this.profileImagePath,
    this.downloadPath, 
    this.musicSource = 'extractor',
    this.activeHomeSections = const ["Popular Artists", 'Recommendations', 'Trending Playlists', 'Desi Hot Hits', 'Ghazal & Sufi Classics', 'Geetmala Legends'],
    this.themeMode = 'black',
    this.customArtists = const [],
    this.podcastActiveSections = const ['Recommended for You', 'Top Trending Global', 'Psychology', 'Philosophy', 'Ghost stories'],
    this.podcastLanguage = 'Any',
    this.customPodcasters = const [],
  });
  
  AppSettings copyWith({
    String? userName,
    String? profileImagePath,
    String? downloadPath, 
    String? musicSource, 
    List<String>? activeHomeSections, 
    String? themeMode,
    List<String>? customArtists,
    List<String>? podcastActiveSections,
    String? podcastLanguage,
    List<String>? customPodcasters,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      downloadPath: downloadPath ?? this.downloadPath,
      musicSource: musicSource ?? this.musicSource,
      activeHomeSections: activeHomeSections ?? this.activeHomeSections,
      themeMode: themeMode ?? this.themeMode,
      customArtists: customArtists ?? this.customArtists,
      podcastActiveSections: podcastActiveSections ?? this.podcastActiveSections,
      podcastLanguage: podcastLanguage ?? this.podcastLanguage,
      customPodcasters: customPodcasters ?? this.customPodcasters,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      userName: prefs.getString('user_name'),
      profileImagePath: prefs.getString('profile_image_path'),
      downloadPath: prefs.getString('download_path'),
      musicSource: prefs.getString('music_source') ?? 'extractor',
      activeHomeSections: prefs.getStringList('home_sections') ?? const ["Popular Artists", 'Recommendations', 'Trending Playlists', 'Desi Hot Hits', 'Ghazal & Sufi Classics', 'Geetmala Legends'],
      themeMode: prefs.getString('theme_mode') ?? 'black',
      customArtists: prefs.getStringList('custom_artists') ?? const [],
      podcastActiveSections: prefs.getStringList('podcast_sections') ?? const ['Recommended for You', 'Top Trending Global', 'Psychology', 'Philosophy', 'Ghost stories'],
      podcastLanguage: prefs.getString('podcast_language') ?? 'Any',
      customPodcasters: prefs.getStringList('custom_podcasters') ?? const [],
    );
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('theme_mode', mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setDownloadPath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('download_path', path);
    state = state.copyWith(downloadPath: path);
  }

  Future<void> setMusicSource(String source) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('music_source', source);
    state = state.copyWith(musicSource: source);
  }

  Future<void> toggleHomeSection(String section, bool isEnabled) async {
    final prefs = ref.read(sharedPrefsProvider);
    List<String> current = List.from(state.activeHomeSections);
    if (isEnabled && !current.contains(section)) {
      current.add(section);
    } else if (!isEnabled && current.contains(section)) {
      current.remove(section);
    }
    await prefs.setStringList('home_sections', current);
    state = state.copyWith(activeHomeSections: current);
  }

  Future<void> togglePodcastSection(String section, bool isEnabled) async {
    final prefs = ref.read(sharedPrefsProvider);
    List<String> current = List.from(state.podcastActiveSections);
    if (isEnabled && !current.contains(section)) {
      current.add(section);
    } else if (!isEnabled && current.contains(section)) {
      current.remove(section);
    }
    await prefs.setStringList('podcast_sections', current);
    state = state.copyWith(podcastActiveSections: current);
  }

  Future<void> setPodcastLanguage(String lang) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('podcast_language', lang);
    state = state.copyWith(podcastLanguage: lang);
  }

  Future<void> addCustomPodcaster(String name) async {
    if (state.customPodcasters.contains(name)) return;
    final prefs = ref.read(sharedPrefsProvider);
    final current = [...state.customPodcasters, name];
    await prefs.setStringList('custom_podcasters', current);
    state = state.copyWith(customPodcasters: current);
  }

  Future<void> removeCustomPodcaster(String name) async {
    final prefs = ref.read(sharedPrefsProvider);
    final current = state.customPodcasters.where((p) => p != name).toList();
    await prefs.setStringList('custom_podcasters', current);
    state = state.copyWith(customPodcasters: current);
  }

  Future<void> addCustomArtist(String artistName) async {
    if (state.customArtists.contains(artistName)) return;
    
    final prefs = ref.read(sharedPrefsProvider);
    final current = [...state.customArtists, artistName];
    await prefs.setStringList('custom_artists', current);
    state = state.copyWith(customArtists: current);
  }

  Future<void> removeCustomArtist(String artistName) async {
    final prefs = ref.read(sharedPrefsProvider);
    final current = state.customArtists.where((a) => a != artistName).toList();
    await prefs.setStringList('custom_artists', current);
    state = state.copyWith(customArtists: current);
  }

  Future<void> setUserName(String name) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('user_name', name);
    state = state.copyWith(userName: name);
  }

  Future<void> setProfileImagePath(String path) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('profile_image_path', path);
    state = state.copyWith(profileImagePath: path);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
