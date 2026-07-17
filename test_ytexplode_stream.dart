import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final id = '3F2uI1JjZ8k'; // Some video
  try {
    final manifest = await yt.videos.streamsClient.getManifest(id);
    final audio = manifest.audioOnly.withHighestBitrate();
    print("Stream URL: ${audio.url}");
  } catch (e) {
    print("YTExplode Error: $e");
  } finally {
    yt.close();
  }
}
