import 'package:flutter/material.dart';

enum AppDestination {
  home,
  discover,
  library,
  downloads,
  playlists,
  community,
}

extension AppDestinationX on AppDestination {
  String get label => switch (this) {
        AppDestination.home => 'Home',
        AppDestination.discover => 'Discover',
        AppDestination.library => 'Library',
        AppDestination.downloads => 'Downloads',
        AppDestination.playlists => 'Playlists',
        AppDestination.community => 'Community',
      };

  IconData get icon => switch (this) {
        AppDestination.home => Icons.home_rounded,
        AppDestination.discover => Icons.travel_explore_rounded,
        AppDestination.library => Icons.library_music_rounded,
        AppDestination.downloads => Icons.download_rounded,
        AppDestination.playlists => Icons.queue_music_rounded,
        AppDestination.community => Icons.groups_rounded,
      };

  String get shortcutLabel => switch (this) {
        AppDestination.home => 'Ctrl+1',
        AppDestination.discover => 'Ctrl+2',
        AppDestination.library => 'Ctrl+3',
        AppDestination.downloads => 'Ctrl+4',
        AppDestination.playlists => 'Ctrl+5',
        AppDestination.community => 'Ctrl+6',
      };
}

const List<String> supportedLanguages = <String>[
  'Hindi',
  'Punjabi',
  'Tamil',
  'Telugu',
  'Bengali',
  'Marathi',
  'Kannada',
  'Malayalam',
  'Gujarati',
  'Urdu',
  'English',
  'Instrumental',
];

const List<String> equalizerPresets = <String>[
  'Bhangra Boost',
  'Ghazal Warmth',
  'Sufi Echo',
  'Classical Tanpura',
  'EDM Drop',
  'Rainy Ghazal',
  'Wedding Dhol',
  'Carvaan Vintage',
  'Monsoon Soft',
  'Temple Brass',
  'Late Night Lofi',
  'Road Trip Bass',
  'Morning Raag',
  'Indie Pop Spark',
  'Retro Vinyl',
  'Bollywood Shine',
  'Punjabi Workout',
  'Mehfil Hall',
  'Santoor Air',
  'Tabla Focus',
  'Qawwali Depth',
  'Folk Open Air',
  'Holi Parade',
  'Navratri Garba',
  'Sufi Bassline',
  'Bhakti Calm',
  'Alaap Detail',
  'Festival Loud',
  'Cinema Dialogue Lift',
  'Rain Cabin',
];

const List<String> aiPromptSuggestions = <String>[
  'Holi Vibes 2026',
  'Rainy Ghazal Night',
  'Punjabi Workout',
  'Temple Morning Calm',
  'Sunday Tamil Drive',
  'Shaadi Dance Floor',
];
