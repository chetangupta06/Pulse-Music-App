import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() async {
  final yt = await YTMusic.create();
  final id = "MPSPPLPuybu4MmbdAmiElP_ensAKD237jFa4NB";
  final cleaned = id.replaceFirst('MPSP', '');
  
  try {
    print("Trying getPlaylist with $cleaned...");
    final p1 = await yt.getPlaylist(cleaned);
    print("getPlaylist success: ${p1['tracks']?.length} tracks");
  } catch (e) {
    print("getPlaylist failed: $e");
  }
}
