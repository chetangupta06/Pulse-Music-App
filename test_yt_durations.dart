import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final ids = [
    'UVkmS2WTfFo', // Modern Dating
    'V2j9G2-Wd3Y', // Another
    'o-YBDTqX_ZU',
    '3F2uI1JjZ8k'
  ];
  
  final start = DateTime.now();
  await Future.wait(ids.map((id) async {
    try {
      final v = await yt.videos.get(id);
      print("$id -> ${v.duration}");
    } catch(e) {
      print("$id error: $e");
    }
  }));
  
  print("Took: ${DateTime.now().difference(start).inMilliseconds}ms");
  yt.close();
}
