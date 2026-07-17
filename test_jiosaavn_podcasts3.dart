import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final urls = [
    'https://www.jiosaavn.com/api.php?__call=webapi.get&token=podcasts&type=show&_format=json&api_version=4',
    'https://www.jiosaavn.com/api.php?__call=webapi.getPodcastHomepage&_format=json&api_version=4'
  ];
  
  for (var url in urls) {
    try {
      final res = await http.get(Uri.parse(url));
      print("URL: $url");
      if (res.statusCode == 200) {
        print("Success, body length: ${res.body.length}");
      } else {
        print("Status: ${res.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
