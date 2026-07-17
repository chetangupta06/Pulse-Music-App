import 'package:flutter/foundation.dart';

import '../../data/demo_seed.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';

class LibraryRepository extends ChangeNotifier {
  LibraryRepository()
      : _favoriteSongIds = <String>{
          DemoSeed.songs.first.id,
          DemoSeed.songs[2].id,
        },
        _playlists = <Playlist>[...DemoSeed.playlists];

  final Set<String> _favoriteSongIds;
  final List<String> _playHistory = <String>[];
  final List<Playlist> _playlists;

  Set<String> get favoriteSongIds => _favoriteSongIds;
  List<String> get playHistory => List<String>.unmodifiable(_playHistory);
  List<Playlist> get playlists => List<Playlist>.unmodifiable(_playlists);

  bool isFavorite(String songId) => _favoriteSongIds.contains(songId);

  void toggleFavorite(String songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    notifyListeners();
  }

  void recordPlayback(Song song) {
    _playHistory.insert(0, song.id);
    if (_playHistory.length > 40) {
      _playHistory.removeLast();
    }
    notifyListeners();
  }

  void saveGeneratedPlaylist(Playlist playlist) {
    _playlists.removeWhere((Playlist item) => item.id == playlist.id);
    _playlists.insert(0, playlist);
    notifyListeners();
  }

  Playlist? importPlaylistLink(String link, List<Song> catalog) {
    final normalized = link.trim();
    if (!normalized.contains('youtube.com') &&
        !normalized.contains('youtu.be')) {
      return null;
    }

    final imported = Playlist(
      id: 'import-${normalized.hashCode}',
      title: 'Imported YouTube Music Mix',
      subtitle: 'Pulled from share link and staged locally for guest mode.',
      songs: catalog.take(5).toList(),
      curator: 'Imported',
      gradient: catalog.first.palette,
      members: const <String>['You'],
    );
    _playlists.insert(0, imported);
    notifyListeners();
    return imported;
  }

  List<Song> favorites(List<Song> catalog) {
    return catalog
        .where((Song song) => _favoriteSongIds.contains(song.id))
        .toList();
  }

  List<Song> recentlyPlayed(List<Song> catalog) {
    final index = <String, Song>{
      for (final Song song in catalog) song.id: song,
    };
    return _playHistory
        .map((String id) => index[id])
        .whereType<Song>()
        .toList();
  }
}
