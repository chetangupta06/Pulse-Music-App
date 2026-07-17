import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  try {
    final yt = await YTMusic.create();
    final results = await yt.search("Raj Shamani podcast", filter: SearchFilter.episodes);
    for (var j in results.take(1)) {
      print("Keys: ${j.keys}");
      print("Full JSON: $j");
    }
  } catch (e) {
    print("YT Error: $e");
  }
}
