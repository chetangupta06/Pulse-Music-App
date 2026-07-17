import 'package:pulse/core/api/jiosaavn_service.dart';

void main() async {
  final service = JioSaavnService();
  final playlists = await service.searchPlaylists("Bollywood Party");
  print("Found playlists: ${playlists.length}");
  for (var p in playlists) {
    print("Playlist: ${p.title} - ${p.id} - ${p.thumbnailUrl}");
  }
}
