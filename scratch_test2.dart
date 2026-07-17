import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = "Bollywood Party";
  try {
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=search.getPlaylistResults&q=$query&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=10');
    final res = await http.get(url);
    print("Status Code: ${res.statusCode}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print("Data type: ${data.runtimeType}");
      if (data is Map && data['results'] != null) {
        print("Found results: ${data['results'].length}");
      } else {
        print("No results found in data: $data");
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}
