import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final query = "Psychology";
  final urls = [
    'https://www.jiosaavn.com/api.php?__call=search.getResults&q=$query&_format=json&api_version=4',
  ];
  
  for (var url in urls) {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) {
           print("Keys: ${body.keys}");
           if (body['shows'] != null) {
              print("Shows data: ${body['shows']}");
           }
           if (body['podcasts'] != null) {
              print("Podcasts data: ${body['podcasts']}");
           }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
