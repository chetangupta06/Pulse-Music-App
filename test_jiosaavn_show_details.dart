import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    // ID from Raj Shamani
    final showId = '138159'; // Raj Shamani - Figuring Out
    
    // Test 1: getDetails
    final url1 = Uri.parse('https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=$showId&_format=json&api_version=4&ctx=web6dot0');
    final res1 = await http.get(url1);
    print("playlist.getDetails status: ${res1.statusCode}");
    if (res1.statusCode == 200) {
      final data = jsonDecode(res1.body);
      print("playlist.getDetails keys: ${data is Map ? data.keys : 'not a map'}");
    }

    // Test 2: show.getHomePage
    final url2 = Uri.parse('https://www.jiosaavn.com/api.php?__call=show.getHomePage&show_id=$showId&_format=json&api_version=4&ctx=web6dot0');
    final res2 = await http.get(url2);
    if (res2.statusCode == 200) {
      final data = jsonDecode(res2.body);
      print("show.getHomePage keys: ${data is Map ? data.keys : 'not a map'}");
      if (data is Map && data['episodes'] != null) {
        print("Episodes count: ${(data['episodes'] as List).length}");
      }
    }
  } catch (e) {
    print("JioSaavn Error: $e");
  }
}
