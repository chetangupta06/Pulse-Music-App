import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  final results = await yt.search("Popular episodes", filter: SearchFilter.episodes);
  
  if (results.isNotEmpty) {
    for (var i = 0; i < 3 && i < results.length; i++) {
      print("Item $i duration: ${results[i]['duration']} type: ${results[i]['duration'].runtimeType}");
      print("Raw item: ${results[i]}");
    }
  } else {
    print("No results");
  }
}
