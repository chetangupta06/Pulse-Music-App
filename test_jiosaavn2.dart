import 'package:jiosaavn/jiosaavn.dart';

void main() async {
  final client = JioSaavnClient();
  try {
    final search = await client.search.songs('Arijit Singh');
    if (search != null && search.data.isNotEmpty) {
      final song = search.data.first;
      print('Song ID: ${song.id}');
      print('Song Title: ${song.title}');
      print('Song Artist: ${song.primaryArtists}');
      print('Song Image: ${song.image?.last.url}');
      
      final details = await client.songs.detailsById([song.id]);
      if (details.isNotEmpty) {
        final d = details.first;
        print('Stream URL: ${d.downloadUrl?.last.url}');
      }
    }
  } catch (e) {
    print(e);
  }
}
