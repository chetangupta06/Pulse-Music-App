import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=autocomplete.get&query=Raj Shamani&_format=json&_marker=0&ctx=web6dot0');
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    print("Keys: ${data.keys}");
    if (data['shows'] != null) {
      print("Shows: ${data['shows']['data']}");
    }
    if (data['podcasts'] != null) {
      print("Podcasts: ${data['podcasts']['data']}");
    }
  } catch (e) {
    print("JioSaavn Error: $e");
  }
}
