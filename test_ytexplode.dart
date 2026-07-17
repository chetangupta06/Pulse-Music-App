import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streamsClient.getManifest('dQw4w9WgXcQ');
    final audio = manifest.audioOnly.withHighestBitrate();
    print('Success: ${audio.url}');
  } catch (e) {
    print('Failed: $e');
  } finally {
    yt.close();
  }
}
