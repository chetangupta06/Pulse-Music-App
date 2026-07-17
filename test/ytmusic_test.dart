import 'package:flutter_test/flutter_test.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() {
  test('YTMusic suggestions', () async {
    final yt = await YTMusic.create();
    final res = await yt.getSearchSuggestions("arij");
    print(res);
  });
}
