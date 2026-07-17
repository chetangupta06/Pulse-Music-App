import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  try {
    final yt = await YTMusic.create();
    final res = await yt.search("Raj Shamani podcast", filter: SearchFilter.podcasts);
    for (var p in res) {
      print("Title: ${p['title']} | Author: ${p['author']} | Publisher: ${p['publisher']}");
    }
    
    print("\nGhost stories podcast:");
    final res2 = await yt.search("Ghost stories podcast", filter: SearchFilter.podcasts);
    for (var p in res2) {
      print("Title: ${p['title']} | Author: ${p['author']} | Publisher: ${p['publisher']}");
    }
  } catch (e) {
    print("YTMusic Error: $e");
  }
}
