import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  try {
    final results = await yt.search("Psychology podcast", filter: SearchFilter.podcasts);
    for (var j in results.take(2)) {
      print("Title: ${j['title']}");
      print("BrowseId: ${j['browseId']}");
    }
  } catch(e) {
     print("Error: $e");
  }
}
