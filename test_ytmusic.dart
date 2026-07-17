import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  final results = await yt.search("Psychology", filter: SearchFilter.episodes);
  print(results.take(2).toList());
  
  final podcasts = await yt.search("Philosophy", filter: SearchFilter.podcasts);
  print(podcasts.take(2).toList());
}
