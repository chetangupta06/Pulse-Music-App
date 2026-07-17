import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final id = '3F2uI1JjZ8k'; // Some video
  final apis = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.lunar.icu',
    'https://piped-api.garudalinux.org',
    'https://pipedapi.smnz.de'
  ];
  
  for (var api in apis) {
    try {
      final res = await dio.get('$api/streams/$id', options: Options(receiveTimeout: const Duration(milliseconds: 3000)));
      if (res.statusCode == 200) {
        final List audioStreams = res.data['audioStreams'] ?? [];
        if (audioStreams.isNotEmpty) {
           print("$api: SUCCESS (Found stream)");
        }
      }
    } catch (e) {
      if (e is DioException) {
        print("$api: FAILED (${e.response?.statusCode})");
      } else {
        print("$api: ERROR $e");
      }
    }
  }
}
