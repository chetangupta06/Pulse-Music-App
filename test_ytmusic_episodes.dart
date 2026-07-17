import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  try {
    final yt = await YTMusic.create();
    final results = await yt.search("Raj Shamani podcast", filter: SearchFilter.episodes);
    for (var j in results.take(3)) {
      print("Keys: ${j.keys}");
      print("duration: ${j['duration']}");
      print("Title: ${j['title']}");
    }
  } catch (e) {
    print("YT Error: $e");
  }
}
