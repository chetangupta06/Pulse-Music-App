import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    final queries = ["Raj Shamani podcast Hindi", "Ghost stories podcast", "Philosophy podcast"];
    for (var q in queries) {
      final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=autocomplete.get&query=$q&_format=json&_marker=0&ctx=web6dot0');
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      print("Query '$q' shows: ${data['shows'] != null ? data['shows']['data'].length : 0}");
    }
  } catch (e) {
    print("JioSaavn Error: $e");
  }
}
