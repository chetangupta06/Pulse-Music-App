import 'package:universal_io/io.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';
import '../models/track.dart';
import '../models/app_playlist.dart';
import 'music_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as ytexp;
import 'extractor_service.dart'; // for _decodeHtml

class YouTubeDlpService implements MusicService {
  File? _binary;
  bool _isDownloading = false;
  final Dio _dio = Dio();

  Future<void> _ensureBinaryExists() async {
    if (_binary != null && await _binary!.exists() && await _binary!.length() > 1000000) return;
    
    final dir = await getApplicationSupportDirectory();
    final exe = File('${dir.path}/yt-dlp.exe');
    
    if (await exe.exists() && await exe.length() < 1000000) {
      print("Removing corrupted or incomplete yt-dlp.exe...");
      await exe.delete();
    }

    if (!await exe.exists()) {
      if (_isDownloading) return; 
      try {
        _isDownloading = true;
        
        if (!await Directory(dir.path).exists()) {
          await Directory(dir.path).create(recursive: true);
        }

        print("Downloading official yt-dlp.exe safely (Redirection enabled)...");
        final res = await _dio.download(
          'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe', 
          exe.path,
          options: Options(
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) PULSE/1.0'},
            followRedirects: true,
            maxRedirects: 10,
            validateStatus: (status) => (status ?? 0) < 500,
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(1);
              stdout.write("\rYT-DLP Download Progress: $progress%");
            }
          },
        );
        if (res.statusCode == 200 && await exe.length() > 5000000) {
          print("\nSuccessfully initialized yt-dlp.exe natively.");
        } else {
          print("\nFatal error: yt-dlp download corrupted.");
          if (await exe.exists()) await exe.delete();
        }
      } catch (e) {
        print("\nFatal error downloading native yt-dlp binary: $e");
        if (await exe.exists()) await exe.delete();
      } finally {
        _isDownloading = false;
      }
    }
    
    if (await exe.exists() && await exe.length() > 5000000) {
      _binary = exe;
    } else {
      _binary = null;
    }
  }

  @override
  Future<List<Track>> search(String query) async {
    final List<Track> tracks = [];
    
    if (kIsWeb) {
      try {
        final yt = ytexp.YoutubeExplode();
        final results = await yt.search.search(query);
        for (final v in results) {
          try {
            tracks.add(Track()
              ..youtubeId = v.id.value.toString()
              ..id = v.id.value.toString()
              ..title = v.title
              ..artist = v.author
              ..thumbnailUrl = v.thumbnails.highResUrl.toString()
              ..durationMs = 0
              ..trackType = 'youtube');
          } catch(e) {}
        }
        yt.close();
        return tracks;
      } catch (e) {
        print('[YTDLP Web] search error: $e');
        return [];
      }
    }

    // For direct URLs, fall back to shell metadata extraction safely.
    if (query.startsWith('http') || query.startsWith('www.')) {
      if (_binary == null || !await _binary!.exists()) return [];
      try {
        final res = await Process.run(_binary!.path, ['-J', query]);
        if (res.exitCode == 0) {
           final j = jsonDecode(res.stdout);
           final t = Track()
              ..youtubeId = j['id']?.toString() ?? ''
              ..title = j['title']?.toString() ?? 'Unknown'
              ..artist = j['channel']?.toString() ?? 'YouTube'
              ..durationMs = ((j['duration'] as num?)?.toInt() ?? 0) * 1000
              ..trackType = 'youtube';
           final thumbs = j['thumbnails'] as List?;
           if (thumbs != null && thumbs.isNotEmpty) {
               t.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
           }
           tracks.add(t);
        }
      } catch(e) { }
      return tracks;
    }

    // Heavy optimization: Pure Dart YouTube Music JSON bypass for searches
    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.songs);
      
      for (var j in results) {
          if (j['videoId'] == null) continue;
          final t = Track();
          t.youtubeId = j['videoId'].toString();
          t.title = j['title']?.toString() ?? 'Unknown';
          
          final artistsList = j['artists'] as List?;
          t.artist = (artistsList != null && artistsList.isNotEmpty) 
              ? artistsList.map((a) => a['name']).join(', ') 
              : 'Unknown Artist';
              
          // Duration is natively formatted string e.g. "3:45"
          if (j['duration'] != null && j['duration'].toString().contains(':')) {
             final parts = j['duration'].toString().split(':');
             if (parts.length == 2) {
               final m = int.tryParse(parts[0]) ?? 0;
               final s = int.tryParse(parts[1]) ?? 0;
               t.durationMs = ((m * 60) + s) * 1000;
             }
          }
          
          final thumbs = j['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
             t.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
          }
          t.trackType = 'youtube';
          tracks.add(t);
      }
    } catch(e) {
       print("YTMusicAPI parsed error: " + e.toString());
    }
    
    return tracks;
  }

  Future<List<Track>> searchEpisodes(String query) async {
    final List<Track> tracks = [];
    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.episodes);
      
      for (var j in results) {
          if (j['videoId'] == null) continue;
          final t = Track();
          t.youtubeId = j['videoId'].toString();
          t.title = j['title']?.toString() ?? 'Unknown';
          t.artist = j['podcast']?['name']?.toString() ?? 'Podcast Episode';
              
          if (j['duration'] != null && j['duration'].toString().contains(':')) {
             final parts = j['duration'].toString().split(':');
             if (parts.length == 3) {
               final h = int.tryParse(parts[0]) ?? 0;
               final m = int.tryParse(parts[1]) ?? 0;
               final s = int.tryParse(parts[2]) ?? 0;
               t.durationMs = ((h * 3600) + (m * 60) + s) * 1000;
             } else if (parts.length == 2) {
               final m = int.tryParse(parts[0]) ?? 0;
               final s = int.tryParse(parts[1]) ?? 0;
               t.durationMs = ((m * 60) + s) * 1000;
             }
          }
          
          final thumbs = j['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
             t.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
          }
          t.trackType = 'youtube';
          tracks.add(t);
      }
    } catch(e) {
       print("YTMusicAPI episodes search error: $e");
    }
    return tracks;
  }

  Future<List<AppPlaylist>> searchPodcasts(String query) async {
    final List<AppPlaylist> playlists = [];
    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.podcasts);
      
      for (var j in results) {
          if (j['browseId'] == null) continue;
          final p = AppPlaylist()
            ..id = j['browseId'].toString()
            ..title = j['title']?.toString() ?? 'Podcast'
            ..author = j['author']?.toString() ?? 'YouTube Podcast'
            ..type = 'youtube';
          
          final thumbs = j['thumbnails'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
             p.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
          }
          playlists.add(p);
      }
    } catch(e) {
       print("YTMusicAPI podcasts search error: $e");
    }
    return playlists;
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    if (kIsWeb) {
      final List<String> activeMirrors = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.in.projectsegfau.lt',
        'https://pipedapi.adminforge.de',
        'https://pipedapi.tokhmi.xyz',
        'https://pipedapi.lunar.icu',
        'https://pipedapi.smnz.de',
      ];
      final completer = Completer<String?>();
      int errors = 0;
      for (final mirror in activeMirrors) {
        _dio.get('$mirror/streams/$id').then((res) {
          if (res.statusCode == 200 && res.data != null) {
            final audioStreams = res.data['audioStreams'] as List?;
            if (audioStreams != null && audioStreams.isNotEmpty) {
              audioStreams.sort((a, b) => ((b['bitrate'] ?? 0) as int).compareTo((a['bitrate'] ?? 0) as int));
              final url = audioStreams.first['url']?.toString();
              if (url != null && !completer.isCompleted) {
                print('[YTDLP Web] Stream via Piped: $url');
                completer.complete(url);
              }
            }
          }
        }).catchError((_) {
          errors++;
          if (errors == activeMirrors.length && !completer.isCompleted) completer.complete(null);
        });
      }
      return completer.future;
    }

    // Stage 1: Ultra-fast Native InnerTube API (Handles 80% of tracks instantly)
    try {
      final res = await _dio.post(
        'https://music.youtube.com/youtubei/v1/player',
        data: {
          "context": {
            "client": {
              "clientName": "ANDROID_MUSIC",
              "clientVersion": "6.02.53",
              "androidSdkVersion": 31,
              "hl": "en",
              "gl": "IN"
            }
          },
          "videoId": id,
          "playbackContext": {
             "contentPlaybackContext": {
                "signatureTimestamp": 19800 
             }
          }
        },
        options: Options(
          headers: {'User-Agent': 'com.google.android.apps.youtube.music/6.02.53 (Linux; U; Android 12; IN) gzip'},
        ),
      );

      if (res.statusCode == 200 && res.data['streamingData'] != null) {
        final formats = res.data['streamingData']['adaptiveFormats'] as List? ?? [];
        final audioFormats = formats.where((f) => f['mimeType']?.toString().contains('audio') == true).toList();
        if (audioFormats.isNotEmpty) {
          audioFormats.sort((a, b) => ((b['averageBitrate'] ?? 0) as int).compareTo((a['averageBitrate'] ?? 0) as int));
          // Only return if it's a direct URL (not ciphered)
          final bestUrl = audioFormats.first['url']?.toString();
          if (bestUrl != null && bestUrl.isNotEmpty) {
            print('[YTDL] Stream via InnerTube Android (Instant): $bestUrl');
            return bestUrl;
          }
        }
      }
    } catch (e) {
      print('[YTDL] InnerTube Native API failed: $e');
    }

    try {
      final List<String> activeMirrors = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.in.projectsegfau.lt',
        'https://pipedapi.adminforge.de',
        'https://pipedapi.tokhmi.xyz',
        'https://pipedapi.lunar.icu',
        'https://pipedapi.smnz.de',
        'https://piped-api.garudalinux.org',
      ];

      final completer = Completer<String?>();
      int errors = 0;
      
      final futures = activeMirrors.map((mirror) async {
        final res = await _dio.get(
          '$mirror/streams/$id',
          options: Options(receiveTimeout: const Duration(milliseconds: 3000), sendTimeout: const Duration(milliseconds: 3000)),
        );
        if (res.statusCode == 200) {
          final List audioStreams = res.data['audioStreams'] ?? [];
          if (audioStreams.isNotEmpty) {
            return audioStreams.first['url']?.toString();
          }
        }
        throw Exception('Mirror failed or empty');
      });

      for (final future in futures) {
        future.then((url) {
          if (!completer.isCompleted) completer.complete(url);
        }).catchError((e) {
          errors++;
          if (errors == activeMirrors.length && !completer.isCompleted) {
            completer.completeError('All proxies failed');
          }
        });
      }

      final fastestUrl = await completer.future;
      if (fastestUrl != null) return fastestUrl;
    } catch (e) {
      print('Fast Piped API concurrent mirrors failed, falling back to local YT-DLP: $e');
    }

    // 2. STABLE NATIVE FALLBACK: YT-DLP Shell Process
    if (!kIsWeb) {
      await _ensureBinaryExists();
      if (_binary != null && await _binary!.exists()) {
        try {
          final res = await Process.run(_binary!.path, [
            '--no-playlist',
            '--youtube-skip-dash-manifest',
            '--get-url',
            '-f', 'ba[ext=m4a]/ba', 
            'https://youtube.com/watch?v=' + id
          ]);

          if (res.exitCode == 0) {
            final url = (res.stdout as String).trim();
            if (url.isNotEmpty) return url;
          } else {
            print("yt-dlp stream exception: " + res.stderr.toString());
          }
        } catch (e) {
          print("Stream local shell exception: " + e.toString());
        }
      }
    }
    return null;
  }

  @override
  Future<List<Track>> getSimilarTracks(String id, {String? artistName, String? currentTitle}) async {
    try {
      final yt = await YTMusic.create();
      final results = await yt.getWatchPlaylist(videoId: id);
      
      String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      final currentNorm = normalize(currentTitle ?? '');
      final seenTitles = <String>{};
      if (currentNorm.isNotEmpty) seenTitles.add(currentNorm);

      final tracksList = results['tracks'] as List? ?? [];
      final List<Track> tracks = [];
      for (var r in tracksList) {
        if (r['videoId'] == id) continue;
        
        final t = Track()
          ..youtubeId = r['videoId']?.toString() ?? ''
          ..title = r['title']?.toString() ?? 'Unknown'
          ..artist = (r['artists'] as List?)?.first['name']?.toString() ?? 'Unknown'
          ..thumbnailUrl = (r['thumbnails'] as List?)?.last['url']?.toString() ?? ''
          ..durationMs = (int.tryParse(r['duration']?.toString() ?? '180') ?? 180) * 1000
          ..trackType = 'youtube';

        final norm = normalize(t.title);
        if (!seenTitles.contains(norm)) {
          tracks.add(t);
          seenTitles.add(norm);
        }
      }
      return tracks;
    } catch (e) {
      print("YTMusic suggestions error: $e");
    }
    return [];
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
            ..type = 'youtube'
            ..thumbnailUrl = p.thumbnails.isNotEmpty ? p.thumbnails.last.url.toString() : '');
        }
        yt.close();
        return lists;
      } catch (e) {
        print('[YTDLP Web] searchPlaylists error: $e');
        return [];
      }
    }

    // yt-dlp typically extracts strictly bounded items cleanly. 
     try {
       final yt = await YTMusic.create();
       final results = await yt.search(query, filter: SearchFilter.playlists);
       final List<AppPlaylist> lists = [];
       for (var j in results) {
           if (j['browseId'] == null) continue;
           final p = AppPlaylist()
             ..id = j['browseId'].toString()
             ..title = j['title']?.toString() ?? 'Unknown';
           p.thumbnailUrl = (j['thumbnails'] as List?)?.last['url']?.toString() ?? '';
           lists.add(p);
       }
       return lists;
     } catch (e) {
       print("YTMusicAPI Playlist parsed error: " + e.toString());
     }
     return [];
  }

  @override
  Future<List<Track>> getPlaylistTracks(String id) async {
    if (kIsWeb) {
      try {
        final yt = ytexp.YoutubeExplode();
        final videos = await yt.playlists.getVideos(id).toList();
        final List<Track> tracks = [];
        for (final v in videos) {
          tracks.add(Track()
            ..youtubeId = v.id.value
            ..id = v.id.value
            ..title = v.title
            ..artist = v.author
            ..durationMs = v.duration?.inMilliseconds ?? 0
            ..thumbnailUrl = v.thumbnails.highResUrl
            ..trackType = 'youtube');
        }
        yt.close();
        return tracks;
      } catch (e) {
        print('[YTDLP Web] getPlaylistTracks error: $e');
        return [];
      }
    }

      try {
          if (id.startsWith('MPSP')) {
            // Podcast browse IDs use a different response structure than regular playlists.
            // We must use the raw InnerTube browse API and parse secondaryContents manually.
            try {
              final browseRes = await _dio.post(
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
                  "browseId": id,
                },
                options: Options(
                  headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
                ),
              );

              if (browseRes.statusCode == 200) {
                final data = browseRes.data;
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
                if (renderers.isNotEmpty) {
                  final List<Track> tracks = [];
                  for (var r in renderers) {
                    final type = r['type'];
                    final renderer = r['data'];
                    
                    String videoId = '';
                    String title = 'Unknown';
                    String artist = 'Podcast';
                    int durationMs = 0;
                    String thumbUrl = '';

                    if (type == 'responsive') {
                      videoId = renderer['playlistItemData']?['videoId']?.toString() ?? '';
                      
                      final flexCols = renderer['flexColumns'] as List?;
                      if (flexCols != null && flexCols.isNotEmpty) {
                        final runs = flexCols[0]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
                        if (runs != null && runs.isNotEmpty) title = runs[0]['text']?.toString() ?? 'Unknown';
                      }
                      if (flexCols != null && flexCols.length > 1) {
                        final runs = flexCols[1]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
                        if (runs != null && runs.isNotEmpty) artist = runs[0]['text']?.toString() ?? 'Podcast';
                      }
                      
                      final fixedCols = renderer['fixedColumns'] as List?;
                      if (fixedCols != null && fixedCols.isNotEmpty) {
                        final durationText = fixedCols[0]['musicResponsiveListItemFixedColumnRenderer']?['text']?['runs']?[0]?['text']?.toString();
                        if (durationText != null) {
                          final parts = durationText.split(':');
                          if (parts.length == 2) durationMs = ((int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0)) * 1000;
                          else if (parts.length == 3) durationMs = ((int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0)) * 1000;
                        }
                      }
                      
                      final thumbs = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
                      if (thumbs != null && thumbs.isNotEmpty) thumbUrl = thumbs.last['url']?.toString() ?? '';
                      
                    } else if (type == 'multirow') {
                      final browseId = renderer['title']?['runs']?[0]?['navigationEndpoint']?['browseEndpoint']?['browseId']?.toString() ?? '';
                      if (browseId.startsWith('MPED')) {
                        videoId = browseId.replaceFirst('MPED', '');
                      }
                      
                      title = renderer['title']?['runs']?[0]?['text']?.toString() ?? 'Unknown';
                      artist = renderer['description']?['runs']?[0]?['text']?.toString() ?? 'Podcast';
                      if (artist.length > 50) artist = artist.substring(0, 50) + '...';
                      
                      final playback = renderer['playbackProgress']?['musicPlaybackProgressRenderer'];
                      if (playback != null) {
                        final durationRuns = playback['durationText']?['runs'] as List?;
                        if (durationRuns != null && durationRuns.length > 1) {
                           final durStr = durationRuns[1]['text']?.toString() ?? '';
                           int hrs = 0; int mins = 0;
                           if (durStr.contains('hr')) {
                              final h = RegExp(r'(\d+)\s*hr').firstMatch(durStr);
                              if (h != null) hrs = int.tryParse(h.group(1) ?? '0') ?? 0;
                           }
                           if (durStr.contains('min')) {
                              final m = RegExp(r'(\d+)\s*min').firstMatch(durStr);
                              if (m != null) mins = int.tryParse(m.group(1) ?? '0') ?? 0;
                           }
                           durationMs = (hrs * 3600 + mins * 60) * 1000;
                        }
                      }
                      
                      final thumbs = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
                      if (thumbs != null && thumbs.isNotEmpty) thumbUrl = thumbs.last['url']?.toString() ?? '';
                    }

                    if (videoId.isNotEmpty) {
                      final t = Track()
                        ..youtubeId = videoId
                        ..id = videoId
                        ..title = title
                        ..artist = artist
                        ..thumbnailUrl = thumbUrl
                        ..durationMs = durationMs
                        ..trackType = 'youtube';
                      tracks.add(t);
                    }
                  }
                  if (tracks.isNotEmpty) return tracks;
                } else {
                  print('[YTDLP] Podcast renderers empty. Raw response: ${data.toString().substring(0, data.toString().length < 500 ? data.toString().length : 500)}...');
                }
              }
            } catch (e) {
              print("InnerTube podcast browse failed: $e");
            }

            // Fallback: try yt-dlp for MPSP playlists
            await _ensureBinaryExists();
            if (_binary != null && await _binary!.exists()) {
              String ytListId = id.substring(4); // Strip MPSP prefix
              final url = "https://youtube.com/playlist?list=$ytListId";
              final res = await Process.run(_binary!.path, ['-J', '--flat-playlist', url]);
              if (res.exitCode == 0) {
                final j = jsonDecode(res.stdout);
                final entries = j['entries'] as List? ?? [];
                final List<Track> tracks = [];
                for (var e in entries) {
                  final t = Track()
                    ..youtubeId = e['id']?.toString() ?? ''
                    ..title = e['title']?.toString() ?? 'Unknown'
                    ..artist = e['channel']?.toString() ?? 'Unknown'
                    ..thumbnailUrl = (e['thumbnails'] as List?)?.last['url']?.toString() ?? ''
                    ..durationMs = (int.tryParse(e['duration']?.toString() ?? '180') ?? 180) * 1000
                    ..trackType = 'youtube';
                  tracks.add(t);
                }
                if (tracks.isNotEmpty) return tracks;
              }
            }
          }

          final yt = await YTMusic.create();
          
          // ID extraction: If id is a full URL or has extra params, clean it
          String playlistId = id;
          if (id.contains('list=')) {
             playlistId = id.split('list=')[1].split('&')[0];
          } else if (id.contains('?list=')) {
             playlistId = id.split('?list=')[1].split('&')[0];
          }
          
          print("Fetching playlist tracks for ID: $playlistId");
          final results = await yt.getPlaylist(playlistId);
          final tracksList = (results is Map) ? (results['tracks'] as List? ?? []) : (results as List? ?? []);
          final List<Track> tracks = [];
          
          for (var j in tracksList) {
              final t = Track()
                ..youtubeId = j['videoId']?.toString() ?? ''
                ..title = j['title']?.toString() ?? 'Unknown'
                ..artist = (j['artists'] as List?)?.first['name']?.toString() ?? 'Unknown'
                ..thumbnailUrl = (j['thumbnails'] as List?)?.last['url']?.toString() ?? ''
                ..durationMs = (int.tryParse(j['duration']?.toString() ?? '180') ?? 180) * 1000
                ..trackType = 'youtube';
              tracks.add(t);
          }
          return tracks;
      } catch (e) {
          print("YTMusicAPI getPlaylistTracks error: " + e.toString());
      }
      return [];
  }

  @override
  Future<String?> getLyrics(String id) async {
    // Reuse identical LRCLIB proxy mechanism mapped earlier
    try {
      // Find explicitly the title via native shell dump:
      await _ensureBinaryExists();
      final titleRes = await Process.run(_binary!.path, ['-O', '%(title)s', 'https://youtube.com/watch?v=' + id]);
      String title = titleRes.exitCode == 0 ? (titleRes.stdout as String).trim() : id;
      title = title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
      
      final lrclibRes = await _dio.get('https://lrclib.net/api/search', queryParameters: {'q': title});
      if (lrclibRes.statusCode == 200) {
        final items = lrclibRes.data as List;
        if (items.isNotEmpty) {
          final first = items.first;
          return first['syncedLyrics']?.toString() ?? first['plainLyrics']?.toString();
        }
      }
    } catch (e) {}
    return null;
  }

  Future<void> downloadTrackNative(String videoId, String savePath, Function(double) onProgress) async {
    await _ensureBinaryExists();
    if (_binary == null || !await _binary!.exists()) throw Exception("yt-dlp binary missing");

    final process = await Process.start(_binary!.path, [
      '--progress',
      '--newline',
      '-f', 'bestaudio[ext=m4a]/bestaudio',
      '--embed-metadata',
      '--embed-thumbnail',
      '-o', savePath,
      'https://youtube.com/watch?v=' + videoId
    ]);

    final progressRegex = RegExp(r'\[download\]\s+([\d\.]+)%');

    process.stdout.transform(utf8.decoder).listen((line) {
      final match = progressRegex.firstMatch(line);
      if (match != null) {
        final percent = double.tryParse(match.group(1)!) ?? 0.0;
        onProgress(percent / 100.0);
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final error = await process.stderr.transform(utf8.decoder).join();
      throw Exception("yt-dlp download failed with exit code $exitCode: $error");
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final yt = await YTMusic.create();
      final List<dynamic> res = await yt.getSearchSuggestions(query);
      return res.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {}
}
