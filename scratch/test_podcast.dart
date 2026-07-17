import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';

import 'package:ytmusicapi_dart/enums.dart';

void main() async {
  final yt = await YTMusic.create();
  print("Searching for podcast...");
  final results = await yt.search("Read People Like a Book: Psychology & Body Language (Hindi Audiobook)", filter: SearchFilter.podcasts);
  
  if (results.isEmpty) {
    print("Not found");
    return;
  }
  
  final browseId = results.first['browseId'];
  print("Found browseId: $browseId");

  try {
    final dio = Dio();
    final browseRes = await dio.post(
      'https://music.youtube.com/youtubei/v1/browse',
      data: {
        "context": {
          "client": {
            "clientName": "WEB_REMIX",
            "clientVersion": "1.20000101.00.00",
            "hl": "en",
            "gl": "IN"
          }
        },
        "browseId": browseId,
      },
      options: Options(
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
      ),
    );

    if (browseRes.statusCode == 200) {
      final data = browseRes.data;
      File('scratch/podcast_dump.json').writeAsStringSync(jsonEncode(data));
      print('Dumped to scratch/podcast_dump.json');
    }
  } catch (e) {
    print(e);
  }
}
