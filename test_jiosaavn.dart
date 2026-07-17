import 'package:jiosaavn/jiosaavn.dart';

void main() async {
  final jiosaavn = Jiosaavn();
  final res = await jiosaavn.search.all("Arijit Singh");
  if (res.songs != null && res.songs!.data.isNotEmpty) {
    final song = res.songs!.data.first;
    print('Found: ${song.title} by ${song.primaryArtists}');
    
    // Fetch details
    final details = await jiosaavn.songs.detailsById([song.id]);
    if (details.isNotEmpty) {
      final s = details.first;
      print('Stream URL: ${s.downloadUrl?.last.url}');
    }
  }
}
