import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() async {
  final yt = await YTMusic.create();
  final browseId = 'MPSPPLPuybu4MmbdAmiElP_ensAKD237jFa4NB';
  
  // Test 1: getPlaylist with full browseId
  try {
    print("=== Test 1: getPlaylist with full browseId ===");
    final results = await yt.getPlaylist(browseId);
    if (results is Map) {
      print("Keys: ${results.keys}");
      final tracks = results['tracks'] as List? ?? [];
      print("Tracks count: ${tracks.length}");
      if (tracks.isNotEmpty) {
        print("First track: ${tracks.first}");
      }
    } else {
      print("Result type: ${results.runtimeType}");
      print("Result: $results");
    }
  } catch (e) {
    print("Test 1 error: $e");
  }
  
  // Test 2: Try getPodcast if it exists
  try {
    print("\n=== Test 2: getAlbum with browseId ===");
    final results = await yt.getAlbum(browseId);
    print("Result: $results");
  } catch (e) {
    print("Test 2 error: $e");
  }

  // Test 3: getPlaylist stripping MPSP  
  try {
    print("\n=== Test 3: getPlaylist with stripped prefix ===");
    final stripped = browseId.substring(4); // PLPuybu4MmbdA...
    final results = await yt.getPlaylist(stripped);
    if (results is Map) {
      print("Keys: ${results.keys}");
      final tracks = results['tracks'] as List? ?? [];
      print("Tracks count: ${tracks.length}");
      if (tracks.isNotEmpty) {
        print("First track title: ${tracks.first['title']}");
      }
    }
  } catch (e) {
    print("Test 3 error: $e");
  }
}
