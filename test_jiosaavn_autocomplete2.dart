import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=autocomplete.get&query=Ghost stories&_format=json&_marker=0&ctx=web6dot0');
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    if (data['shows'] != null) {
      print("Shows: ${data['shows']['data']}");
    }
  } catch (e) {
    print("JioSaavn Error: $e");
  }
}
