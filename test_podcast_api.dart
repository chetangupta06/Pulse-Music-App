import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  final id = "MPSPPLPuybu4MmbdAmiElP_ensAKD237jFa4NB";
  
  try {
    print("Trying getPodcast...");
    final p1 = await (yt as dynamic).getPodcast(id);
    print("getPodcast success: ${p1.keys}");
  } catch (e) {
    print("getPodcast failed: $e");
  }

  try {
    print("Trying getWatchPlaylist with playlistId...");
    final p2 = await yt.getWatchPlaylist(playlistId: id);
    print("getWatchPlaylist success: ${p2['tracks']?.length} tracks");
  } catch (e) {
    print("getWatchPlaylist failed: $e");
  }
}
