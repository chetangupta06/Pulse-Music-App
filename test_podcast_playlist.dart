import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  final results = await yt.search("Psychology podcast", filter: SearchFilter.podcasts);
  if (results.isEmpty) {
    print("No podcasts found");
    return;
  }
  final id = results.first['browseId'];
  print("Found podcast ID: $id");
  
  try {
    print("Trying getPlaylist...");
    final p1 = await yt.getPlaylist(id);
    print("getPlaylist success: ${p1['tracks']?.length} tracks");
  } catch (e) {
    print("getPlaylist failed: $e");
  }

  try {
    print("Trying getPlaylist with VL prefix...");
    final p2 = await yt.getPlaylist("VL$id");
    print("getPlaylist with VL success: ${p2['tracks']?.length} tracks");
  } catch (e) {
    print("getPlaylist with VL failed: $e");
  }
}
