import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print("\n--- JioSaavn Playlists ---");
  try {
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=search.getPlaylistResults&q=Raj Shamani podcast&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=10');
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    if (data is Map && data['results'] != null) {
      for (var p in data['results']) {
        print("Title: ${p['title']} | Author: ${p['subtitle'] ?? 'none'}");
      }
    }
  } catch (e) {
    print("JioSaavn Error: $e");
  }
}
