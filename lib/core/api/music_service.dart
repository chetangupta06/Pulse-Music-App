import '../models/track.dart';
import '../models/app_playlist.dart';

abstract class MusicService {
  Future<List<Track>> search(String query);
  Future<List<AppPlaylist>> searchPlaylists(String query);
  Future<List<AppPlaylist>> searchPodcasts(String query);
  Future<List<Track>> searchEpisodes(String query);
  Future<List<Track>> getPlaylistTracks(String id);
  Future<List<Track>> getSimilarTracks(String id, {String? artistName, String? currentTitle});
  Future<String?> getStreamUrl(String id);
  Future<String?> getLyrics(String id);
  Future<List<String>> getSearchSuggestions(String query);
  void dispose();
}
