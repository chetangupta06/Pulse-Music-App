
import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('scratch/podcast_dump.json');
  final data = jsonDecode(file.readAsStringSync());

  List<dynamic> extractRenderers(dynamic node) {
    List<dynamic> results = [];
    if (node is Map) {
      if (node.containsKey('musicResponsiveListItemRenderer')) {
        results.add({'type': 'responsive', 'data': node['musicResponsiveListItemRenderer']});
      } else if (node.containsKey('musicMultiRowListItemRenderer')) {
        results.add({'type': 'multirow', 'data': node['musicMultiRowListItemRenderer']});
      }
      for (var value in node.values) {
        results.addAll(extractRenderers(value));
      }
    } else if (node is List) {
      for (var item in node) {
        results.addAll(extractRenderers(item));
      }
    }
    return results;
  }

  final renderers = extractRenderers(data);
  print('Found \ renderers');
  for (var r in renderers) {
    if (r['type'] == 'multirow') {
      final d = r['data'];
      final title = d['title']?['runs']?[0]?['text'];
      print('Title: ');
    }
  }
}
