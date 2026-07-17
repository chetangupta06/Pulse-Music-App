import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final listId = "1208889749"; // Bollywood Love Songs
  final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=' + listId + '&_format=json&api_version=4&ctx=web6dot0');
  
  final res = await http.get(url);
  print('Status: ' + res.statusCode.toString());
  
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    print(data.toString().substring(0, 500)); // Print first 500 chars to see structure
    final list = data['list'] as List?;
    if (list != null) {
      print('Songs: ' + list.length.toString());
    }
  }
}
