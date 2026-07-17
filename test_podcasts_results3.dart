import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  try {
    final yt = await YTMusic.create();
    final res = await yt.search("Raj Shamani podcast Hindi", filter: SearchFilter.podcasts);
    print("Raj Shamani podcast Hindi results: ${res.length}");
    
    final res2 = await yt.search("Ghost stories podcast Hindi", filter: SearchFilter.podcasts);
    print("Ghost stories podcast Hindi results: ${res2.length}");
  } catch (e) {
    print("YTMusic Error: $e");
  }
}
