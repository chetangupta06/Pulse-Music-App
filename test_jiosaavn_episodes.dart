import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    final showId = '138159'; // Raj Shamani
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=show.getHomePage&show_id=$showId&_format=json&api_version=4&ctx=web6dot0');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['episodes'] != null) {
        final ep = data['episodes'][0];
        print("Episode keys: ${ep.keys}");
        print("Title: ${ep['title']}");
        print("Duration: ${ep['duration']}");
        print("Image: ${ep['image']}");
        print("More info: ${ep['more_info']}");
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}
