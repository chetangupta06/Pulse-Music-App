import '../../models/playlist.dart';
import '../../models/song.dart';

class DiscoveryEngine {
  const DiscoveryEngine();

  List<Song> searchSongs(String query, List<Song> catalog, {String? language}) {
    final normalized = query.trim().toLowerCase();
    return catalog.where((Song song) {
      final languageMatch =
          language == null || language == 'All' || song.language == language;
      if (normalized.isEmpty) {
        return languageMatch;
      }
      final haystack = <String>[
        song.title,
        song.artist,
        song.album,
        song.language,
        song.genre,
        song.mood,
      ].join(' ').toLowerCase();
      return languageMatch && haystack.contains(normalized);
    }).toList();
  }

  List<Song> relatedSongs(Song seed, List<Song> catalog) {
    return catalog
        .where(
          (Song song) =>
              song.id != seed.id &&
              (song.language == seed.language ||
                  song.genre == seed.genre ||
                  song.mood == seed.mood),
        )
        .take(8)
        .toList();
  }

  Playlist generateAiPlaylist(String prompt, List<Song> catalog) {
    final normalized = prompt.toLowerCase();
    final shortlisted = catalog
        .where((Song song) {
          if (normalized.contains('rain')) {
            return song.mood == 'Rain' || song.genre == 'Ghazal Pop';
          }
          if (normalized.contains('workout') || normalized.contains('party')) {
            return song.mood == 'Workout' ||
                song.mood == 'Party' ||
                song.genre == 'Dance';
          }
          if (normalized.contains('bhakti') || normalized.contains('temple')) {
            return song.genre == 'Bhakti' || song.genre == 'Classical';
          }
          if (normalized.contains('tamil')) {
            return song.language == 'Tamil';
          }
          if (normalized.contains('romantic') || normalized.contains('love')) {
            return song.mood == 'Romantic';
          }
          return song.language == 'Hindi' || song.mood == 'Celebration';
        })
        .take(6)
        .toList();

    final songs = shortlisted.isEmpty ? catalog.take(6).toList() : shortlisted;

    return Playlist(
      id: 'ai-${prompt.hashCode}',
      title: prompt,
      subtitle: 'Generated locally from mood, language, and festival cues.',
      songs: songs,
      curator: 'AI Chaska',
      gradient: songs.first.palette,
      members: const <String>['You'],
    );
  }

  List<Song> madeForYou(List<Song> catalog) {
    return catalog
        .where((Song song) => song.language == 'Hindi' || song.mood == 'Rain')
        .take(6)
        .toList();
  }

  List<Song> trending(List<Song> catalog) {
    return catalog.reversed.take(8).toList();
  }
}
