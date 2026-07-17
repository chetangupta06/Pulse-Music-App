import 'package:jiosaavn/jiosaavn.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as ytexp;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/track.dart';
import '../models/app_playlist.dart';
import 'music_service.dart';

class JioSaavnService implements MusicService {
  final JioSaavnClient _client;

  JioSaavnService() : _client = JioSaavnClient();

  @override
  Future<List<Track>> search(String query) async {
    if (kIsWeb) {
      try {
        final yt = ytexp.YoutubeExplode();
        final results = await yt.search.search(query);
        final List<Track> tracks = [];
        for (final v in results) {
          try {
            tracks.add(Track()
              ..youtubeId = v.id.value.toString()
              ..id = v.id.value.toString()
              ..title = _decodeHtml(v.title)
              ..artist = _decodeHtml(v.author)
              ..thumbnailUrl = v.thumbnails.highResUrl.toString()
              ..durationMs = 0
              ..trackType = 'jiosaavn');
          } catch(e) {}
        }
        yt.close();
        return tracks;
      } catch (e) {
        return [];
      }
    }

    try {
      final res = await _client.search.songs(query);
      if (res == null || res.results.isEmpty) return [];
      
      return res.results.map((s) {
        return Track()
          ..id = s.id
          ..youtubeId = s.id // We use youtubeId for all IDs to maintain DB consistency
          ..title = _decodeHtml(s.name ?? 'Unknown')
          ..artist = _decodeHtml(s.primaryArtists)
          ..durationMs = (int.tryParse(s.duration) ?? 180) * 1000
          ..thumbnailUrl = s.image?.last.link ?? ''
          ..trackType = 'jiosaavn';
      }).toList();
    } catch (e) {
      print('[JioSaavn] Search error: $e');
      return [];
    }
  }

  @override
  Future<List<AppPlaylist>> searchPlaylists(String query) async {
    if (kIsWeb) {
      try {
        final yt = ytexp.YoutubeExplode();
        final results = await yt.search.search(query);
        final List<AppPlaylist> lists = [];
        for (final p in results.whereType<ytexp.SearchPlaylist>()) {
          lists.add(AppPlaylist()
            ..id = p.id.value
            ..title = p.title
            ..type = 'jiosaavn'
            ..thumbnailUrl = p.thumbnails.isNotEmpty ? p.thumbnails.last.url.toString() : '');
        }
        yt.close();
        return lists;
      } catch(e) {}
    }

    try {
      final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=search.getPlaylistResults&q=$query&_format=json&_marker=0&api_version=4&ctx=web6dot0&n=10');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['results'] != null) {
          final results = data['results'] as List;
          return results.map((p) {
            return AppPlaylist()
              ..id = p['id']?.toString() ?? ''
              ..title = _decodeHtml(p['title']?.toString() ?? 'Unknown')
              ..thumbnailUrl = p['image']?.toString() ?? ''
              ..type = 'jiosaavn';
          }).toList();
        }
      }
    } catch (e) {
      print('[JioSaavn raw] Search Playlists error: $e');
    }
    return [];
  }

  @override
  Future<List<AppPlaylist>> searchPodcasts(String query) async {
    try {
      final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=autocomplete.get&query=$query&_format=json&_marker=0&ctx=web6dot0');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['shows'] != null) {
          final results = data['shows']['data'] as List;
          return results.map((p) {
            return AppPlaylist()
              ..id = '${p['id']}_show'
              ..title = _decodeHtml(p['title']?.toString() ?? 'Podcast')
              ..author = 'JioSaavn Show'
              ..thumbnailUrl = p['image']?.toString() ?? ''
              ..type = 'jiosaavn_show';
          }).toList();
        }
      }
    } catch (e) {
      print('[JioSaavn] Search Podcasts error: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> searchEpisodes(String query) async {
    // Fallback to song search for episodes
    return search("$query podcast");
  }

  @override
  Future<List<Track>> getPlaylistTracks(String id) async {
    if (id.endsWith('_show')) {
       final showId = id.replaceAll('_show', '');
       try {
         final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=show.getHomePage&show_id=$showId&_format=json&api_version=4&ctx=web6dot0');
         final res = await http.get(url);
         if (res.statusCode == 200) {
           final data = jsonDecode(res.body);
           if (data is Map && data['episodes'] != null) {
             final list = data['episodes'] as List;
             return list.map((t) {
               final moreInfo = t['more_info'] ?? {};
               return Track()
                 ..id = t['id']?.toString() ?? ''
                 ..title = _decodeHtml(t['title']?.toString() ?? 'Unknown')
                 ..artist = _decodeHtml(moreInfo['show_title']?.toString() ?? 'Podcast')
                 ..thumbnailUrl = t['image']?.toString() ?? ''
                 ..durationMs = (int.tryParse(moreInfo['duration']?.toString() ?? '0') ?? 0) * 1000
                 ..trackType = 'jiosaavn_show';
             }).toList();
           }
         }
       } catch (e) {
         print('[JioSaavn] show.getHomePage error: $e');
       }
       return [];
    }

    try {
      final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=$id&_format=json&api_version=4&ctx=web6dot0');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['list'] != null) {
          final list = data['list'] as List;
          return list.map((s) {
            return Track()
              ..id = s['id']?.toString() ?? ''
              ..youtubeId = s['id']?.toString() ?? ''
              ..title = _decodeHtml(s['title']?.toString() ?? 'Unknown')
              ..artist = _decodeHtml(s['more_info']?['artist_map']?['primary_artists']?[0]?['name']?.toString() ?? s['subtitle']?.toString() ?? 'Unknown')
              ..durationMs = (int.tryParse(s['more_info']?['duration']?.toString() ?? '180') ?? 180) * 1000
              ..thumbnailUrl = s['image']?.toString() ?? ''
              ..trackType = 'jiosaavn';
          }).toList();
        }
      }
    } catch (e) {
      print('[JioSaavn raw] getPlaylistTracks error: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> getSimilarTracks(String id, {String? artistName, String? currentTitle}) async {
    try {
      String query = artistName ?? '';
      if (query.isEmpty) {
        final details = await _client.songs.detailsById([id]);
        if (details.isNotEmpty) {
          query = details.first.primaryArtists.split(',').first.trim();
        }
      }
      if (query.isNotEmpty) {
        final res = await _client.search.songs(query);
        if (res != null && res.results.isNotEmpty) {
          return res.results.where((s) => s.id != id).map((s) {
            return Track()
              ..id = s.id
              ..youtubeId = s.id
              ..title = _decodeHtml(s.name ?? 'Unknown')
              ..artist = _decodeHtml(s.primaryArtists)
              ..durationMs = (int.tryParse(s.duration) ?? 180) * 1000
              ..thumbnailUrl = s.image?.last.link ?? ''
              ..trackType = 'jiosaavn';
          }).take(15).toList();
        }
      }
    } catch (e) {
      print('[JioSaavn] getSimilarTracks error: $e');
    }
    return [];
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    try {
      final details = await _client.songs.detailsById([id]);
      if (details.isNotEmpty) {
        final s = details.first;
        if (s.downloadUrl != null && s.downloadUrl!.isNotEmpty) {
          final url = s.downloadUrl!.last.link;
          print('[JioSaavn] Stream URL extracted: $url');
          return url;
        }
      }
    } catch (e) {
      print('[JioSaavn] getStreamUrl error: $e');
    }
    return null;
  }

  @override
  Future<String?> getLyrics(String id) async {
    // The lyrics endpoint is not exposed in this package version. 
    // We would fallback to LRCLib here in production, but for now return null
    // to let the UI know lyrics aren't available via JioSaavn natively.
    return null;
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final yt = await YTMusic.create(); // Fallback to YTMusic for suggestions since jiosaavn might not have a clean suggestion API in this package
      final List<dynamic> res = await yt.getSearchSuggestions(query);
      return res.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    // No explicit dispose needed for JioSaavnClient default
  }

  String _decodeHtml(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&ndash;', '\u2013')
        .replaceAll('&mdash;', '\u2014');
  }
}
