class Track {
  String id = '';
  String youtubeId = '';
  String title = '';
  String artist = '';
  String thumbnailUrl = '';
  int durationMs = 0;
  String trackType = ''; // "favorite", "downloaded", "history"
  
  bool isDownloaded = false;
  String? localPath;
  String? syncedLyrics; 
  
  Map<String, dynamic> toJson() => {
    'id': id, 'youtubeId': youtubeId, 'title': title, 'artist': artist,
    'thumbnailUrl': thumbnailUrl, 'durationMs': durationMs, 
    'trackType': trackType, 'isDownloaded': isDownloaded, 'localPath': localPath
  };
  
  static String decodeHtml(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', "/")
        .replaceAll('&ndash;', "–")
        .replaceAll('&mdash;', "—");
  }

  String get effectiveThumbnailUrl {
    // Use the native thumbnail URL if available. For YT Music tracks, this is a perfectly 
    // cropped square album art (e.g. lh3.googleusercontent.com) which fits our UI boxes beautifully.
    // Fall back to hqdefault.jpg ONLY if the thumbnail is missing.
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('file:///')) {
      // For images hosted on Google's image servers (used by YT Music), we can manipulate the 
      // parameters after the '=' sign to request a specific size and cropping behavior.
      // -c forces a center-crop. This is critical for music videos (16:9) where YT Music normally 
      // pads the image with black bars to make it square. -c removes the bars and fills the square.
      if (thumbnailUrl.contains('googleusercontent.com') || thumbnailUrl.contains('ggpht.com')) {
        if (thumbnailUrl.contains('=')) {
          return thumbnailUrl.split('=').first + '=w544-h544-c';
        }
      }
      return thumbnailUrl;
    }
    
    // Fallback for tracks with missing artwork
    if (youtubeId.isNotEmpty) {
      return "https://i.ytimg.com/vi/$youtubeId/mqdefault.jpg";
    }
    
    if (thumbnailUrl.isEmpty || thumbnailUrl.startsWith('file:///')) {
      return 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?q=80&w=400&auto=format&fit=crop';
    }
    return thumbnailUrl;
  }

  static Track fromJson(Map<String, dynamic> j) {
    return Track()
      ..id = j['id'] ?? ''
      ..youtubeId = j['youtubeId'] ?? ''
      ..title = decodeHtml(j['title'] ?? '')
      ..artist = decodeHtml(j['artist'] ?? '')
      ..thumbnailUrl = j['thumbnailUrl'] ?? ''
      ..durationMs = j['durationMs'] ?? 0
      ..trackType = j['trackType'] ?? ''
      ..isDownloaded = j['isDownloaded'] ?? false
      ..localPath = j['localPath'];
  }
}
