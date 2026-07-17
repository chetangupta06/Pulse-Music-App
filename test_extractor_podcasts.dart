import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final query = "Raj Shamani podcast";
    final res = await yt.search.getPlaylists(query);
    for (var p in res) {
      print("Title: ${p.title} | Author: ${p.author}");
    }
  } catch (e) {
    print("YT Explode Error: $e");
  } finally {
    yt.close();
  }
}
