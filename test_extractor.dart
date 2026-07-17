import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // Mock path_provider for CLI
  // We'll just run yt-dlp.exe locally if it exists or use Piped
  final id = 'dQw4w9WgXcQ'; // Rick Astley
  final dio = Dio();
  final mirrors = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.adminforge.de',
  ];

  for (final mirror in mirrors) {
    print('Trying $mirror...');
    try {
      final res = await dio.get('$mirror/streams/$id', options: Options(receiveTimeout: const Duration(milliseconds: 5000)));
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final List audioStreams = res.data['audioStreams'] ?? [];
        print('Found ${audioStreams.length} audio streams');
        return;
      }
    } catch (e) {
      print('Error on $mirror: $e');
    }
  }
}
