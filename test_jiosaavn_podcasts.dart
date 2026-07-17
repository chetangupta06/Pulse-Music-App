import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final query = "Psychology";
  final urls = [
    'https://www.jiosaavn.com/api.php?__call=search.getPodcastResults&q=$query&_format=json&api_version=4',
    'https://www.jiosaavn.com/api.php?__call=search.getShowResults&q=$query&_format=json&api_version=4',
    'https://www.jiosaavn.com/api.php?__call=search.getMoreResults&q=$query&_format=json&api_version=4&type=podcasts'
  ];
  
  for (var url in urls) {
    try {
      final res = await http.get(Uri.parse(url));
      print("URL: $url");
      print("Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) {
           print("Keys: ${body.keys}");
           if (body['results'] != null) {
              print("Results count: ${(body['results'] as List).length}");
           }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    print("---");
  }
}
