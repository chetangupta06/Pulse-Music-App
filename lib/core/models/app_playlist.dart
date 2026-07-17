import 'track.dart';

class AppPlaylist {
  String id = '';
  String title = '';
  String author = '';
  String thumbnailUrl = '';
  String type = 'saavn'; // Origin engine
  List<Track>? tracks;

  String get effectiveThumbnailUrl {
    if (thumbnailUrl.isEmpty || thumbnailUrl.startsWith('file:///')) {
      return 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?q=80&w=400&auto=format&fit=crop';
    }
    if (thumbnailUrl.contains('googleusercontent.com') || thumbnailUrl.contains('ggpht.com')) {
      if (thumbnailUrl.contains('=')) {
        return thumbnailUrl.split('=').first + '=w544-h544-c';
      }
    }
    return thumbnailUrl;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'type': type,
    'tracks': tracks?.map((t) => t.toJson()).toList()
  };

  static AppPlaylist fromJson(Map<String, dynamic> j) {
    return AppPlaylist()
      ..id = j['id'] ?? ''
      ..title = j['title'] ?? ''
      ..thumbnailUrl = j['thumbnailUrl'] ?? ''
      ..type = j['type'] ?? 'saavn'
      ..tracks = (j['tracks'] as List?)?.map((x) => Track.fromJson(x as Map<String, dynamic>)).toList();
  }
}
