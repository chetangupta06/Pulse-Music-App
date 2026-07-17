import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final id = '3F2uI1JjZ8k'; // Some video
  try {
    final pipedRes = await dio.get('https://pipedapi.kavin.rocks/streams/$id');
    print("Status: ${pipedRes.statusCode}");
    if (pipedRes.statusCode == 200) {
      final List audioStreams = pipedRes.data['audioStreams'] ?? [];
      print("Audio streams found: ${audioStreams.length}");
      if (audioStreams.isNotEmpty) {
         print("First stream: ${audioStreams.first['url']}");
      }
    }
  } catch (e) {
    if (e is DioException) {
      print("Piped error: ${e.response?.statusCode} - ${e.response?.data}");
    } else {
      print("Error: $e");
    }
  }
}
