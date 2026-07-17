import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as ytexp;

import '../models/track.dart';
import '../models/app_playlist.dart';
import 'music_service.dart';

/// ExtractorService — mirrors the architecture of the `extractor` pub package
/// (ashishpipaliya/extractor) but runs natively on Windows using yt-dlp.
///
/// The extractor package is Android-only (native Kotlin). This service provides
/// the same functionality on Windows:
///   - Search: ytmusicapi_dart (pure Dart, no binary needed)
///   - Stream URLs: Piped API (fast) → yt-dlp.exe (reliable fallback)
///   - Lyrics: LRCLib synced lyrics
///   - Playlists: YouTube Music API
///   - Similar tracks: YT Music "watch playlist" radio
class ExtractorService implements MusicService {
  File? _binary;
  bool _isDownloading = false;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
  ));

  // Multiple fast Piped API mirrors — tries each in order for redundancy
  static const List<String> _pipedMirrors = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.adminforge.de',
  ];

  // ─── Binary Management ───────────────────────────────────────────────────

  Future<void> _ensureBinaryExists() async {
    if (_binary != null && await _binary!.exists() && await _binary!.length() > 1000000) return;

    final dir = await getApplicationSupportDirectory();
    final exe = File('${dir.path}/yt-dlp.exe');

    if (await exe.exists() && await exe.length() < 1000000) {
      print('[Extractor] Removing corrupted yt-dlp.exe...');
      await exe.delete();
    }

    if (!await exe.exists()) {
      if (_isDownloading) return;
      try {
        _isDownloading = true;
        if (!await Directory(dir.path).exists()) {
          await Directory(dir.path).create(recursive: true);
        }
        print('[Extractor] Downloading official yt-dlp.exe...');
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
              stdout.write('\r[Extractor] yt-dlp: ${(received / total * 100).toStringAsFixed(1)}%');
            }
          },
        );
        if (res.statusCode == 200 && await exe.length() > 5000000) {
          print('\n[Extractor] yt-dlp.exe securely downloaded and verified.');
        } else {
          print('\n[Extractor] yt-dlp download failed or corrupted.');
          if (await exe.exists()) await exe.delete();
        }
      } catch (e) {
        print('[Extractor] Failed to download yt-dlp: $e');
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

  // ─── Search ──────────────────────────────────────────────────────────────

  @override
  Future<List<Track>> search(String query) async {
    // Direct URL: extract metadata via yt-dlp
    if (query.startsWith('http') || query.startsWith('www.')) {
      return _searchByUrl(query);
    }

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
              ..trackType = 'extractor');
          } catch(e) {}
        }
        yt.close();
        return tracks;
      } catch (e) {
        print('[Extractor Web] search error: $e');
        return [];
      }
    }

    final List<Track> tracks = [];
    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.songs);

      for (final j in results) {
        if (j['videoId'] == null) continue;
        final t = Track()
          ..youtubeId = j['videoId'].toString()
          ..id = j['videoId'].toString()
          ..title = _decodeHtml(j['title']?.toString() ?? 'Unknown')
          ..trackType = 'extractor';

        final artistsList = j['artists'] as List?;
        t.artist = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Unknown Artist';

        // Parse duration string "3:45"
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

        tracks.add(t);
      }
    } catch (e) {
      print('[Extractor] search error: $e');
    }
    return tracks;
  }

  Future<List<Track>> _searchByUrl(String url) async {
    await _ensureBinaryExists();
    if (_binary == null || !await _binary!.exists()) return [];
    try {
      final res = await Process.run(_binary!.path, ['-J', '--no-playlist', url]);
      if (res.exitCode == 0) {
        final j = jsonDecode(res.stdout as String);
        final t = Track()
          ..youtubeId = j['id']?.toString() ?? ''
          ..id = j['id']?.toString() ?? ''
          ..title = j['title']?.toString() ?? 'Unknown'
          ..artist = j['channel']?.toString() ?? j['uploader']?.toString() ?? 'Unknown'
          ..durationMs = ((j['duration'] as num?)?.toInt() ?? 0) * 1000
          ..trackType = 'extractor';
        final thumbs = j['thumbnails'] as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          t.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
        }
        return [t];
      }
    } catch (e) {
      print('[Extractor] URL extract error: $e');
    }
    return [];
  }

  // ─── Playlists ───────────────────────────────────────────────────────────

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
            ..title = _decodeHtml(p.title)
            ..type = 'extractor'
            ..thumbnailUrl = p.thumbnails.isNotEmpty ? p.thumbnails.last.url.toString() : '');
        }
        yt.close();
        return lists;
      } catch (e) {
        print('[Extractor Web] searchPlaylists error: $e');
        return [];
      }
    }

    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.playlists);
      final List<AppPlaylist> lists = [];
      for (final j in results) {
        if (j['browseId'] == null) continue;
        final p = AppPlaylist()
          ..id = j['browseId'].toString()
          ..title = _decodeHtml(j['title']?.toString() ?? 'Unknown')
          ..type = 'extractor';
        final thumbs = j['thumbnails'] as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          p.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
        }
        lists.add(p);
      }
      return lists;
    } catch (e) {
      print('[Extractor] searchPlaylists error: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> getPlaylistTracks(String id) async {
    try {
      // Handle podcast browse IDs (MPSP...) with raw InnerTube browse API
      if (id.startsWith('MPSP')) {
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
                  // Usually first sentence or up to a limit for artist/description
                  if (artist.length > 50) artist = artist.substring(0, 50) + '...';
                  
                  final playback = renderer['playbackProgress']?['musicPlaybackProgressRenderer'];
                  if (playback != null) {
                    final durationRuns = playback['durationText']?['runs'] as List?;
                    if (durationRuns != null && durationRuns.length > 1) {
                       final durStr = durationRuns[1]['text']?.toString() ?? '';
                       // Parsing '1 hr 21 min' or '45 min'
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
                  tracks.add(Track()
                    ..youtubeId = videoId
                    ..id = videoId
                    ..title = _decodeHtml(title)
                    ..artist = _decodeHtml(artist)
                    ..thumbnailUrl = thumbUrl
                    ..durationMs = durationMs
                    ..trackType = 'extractor');
                }
              }
              if (tracks.isNotEmpty) return tracks;
            } else {
               print('[Extractor] Podcast renderers empty. Raw response: ${data.toString().substring(0, data.toString().length < 500 ? data.toString().length : 500)}...');
            }
          }
        } catch (e) {
          print('[Extractor] InnerTube podcast browse failed: $e');
        }
      }

      if (kIsWeb) {
        try {
          final yt = ytexp.YoutubeExplode();
          final playlist = await yt.playlists.get(id);
          final videos = await yt.playlists.getVideos(id).toList();
          final List<Track> tracks = [];
          for (final v in videos) {
            tracks.add(Track()
              ..youtubeId = v.id.value
              ..id = v.id.value
              ..title = _decodeHtml(v.title)
              ..artist = _decodeHtml(v.author)
              ..durationMs = v.duration?.inMilliseconds ?? 0
              ..thumbnailUrl = v.thumbnails.highResUrl
              ..trackType = 'extractor');
          }
          yt.close();
          return tracks;
        } catch (e) {
          print('[Extractor Web] getPlaylistTracks error: $e');
          return [];
        }
      }

      final yt = await YTMusic.create();

      // Clean playlist ID from full URLs
      String playlistId = id;
      if (id.contains('list=')) {
        playlistId = id.split('list=')[1].split('&')[0];
      } else if (id.contains('?list=')) {
        playlistId = id.split('?list=')[1].split('&')[0];
      }

      final results = await yt.getPlaylist(playlistId);
      final tracksList = (results is Map)
          ? (results['tracks'] as List? ?? [])
          : (results as List? ?? []);

      final List<Track> tracks = [];
      for (final j in tracksList) {
        if (j['videoId'] == null) continue;
        final t = Track()
          ..youtubeId = j['videoId'].toString()
          ..id = j['videoId'].toString()
          ..title = _decodeHtml(j['title']?.toString() ?? 'Unknown')
          ..artist = (j['artists'] as List?)?.isNotEmpty == true
              ? (j['artists'] as List).first['name']?.toString() ?? 'Unknown'
              : 'Unknown'
          ..durationMs = (int.tryParse(j['duration']?.toString() ?? '180') ?? 180) * 1000
          ..trackType = 'extractor';

        final thumbs = j['thumbnails'] as List?;
        if (thumbs != null && thumbs.isNotEmpty) {
          t.thumbnailUrl = thumbs.last['url']?.toString() ?? '';
        }
        tracks.add(t);
      }
      return tracks;
    } catch (e) {
      print('[Extractor] getPlaylistTracks error: $e');
    }
    return [];
  }

  // ─── Similar Tracks / Radio ──────────────────────────────────────────────

  @override
  Future<List<Track>> getSimilarTracks(String id, {String? artistName, String? currentTitle}) async {
    // Stage 1: YT Music watch playlist (radio)
    try {
      final yt = await YTMusic.create();
      final results = await yt.getWatchPlaylist(videoId: id);

      String normalize(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      final currentNorm = normalize(currentTitle ?? '');
      final seenTitles = <String>{};
      if (currentNorm.isNotEmpty) seenTitles.add(currentNorm);

      final tracksList = results['tracks'] as List? ?? [];
      final List<Track> tracks = [];
      for (final r in tracksList) {
        if (r['videoId'] == null || r['videoId'] == id) continue;
        final t = Track()
          ..youtubeId = r['videoId'].toString()
          ..id = r['videoId'].toString()
          ..title = _decodeHtml(r['title']?.toString() ?? 'Unknown')
          ..artist = (r['artists'] as List?)?.isNotEmpty == true
              ? (r['artists'] as List).first['name']?.toString() ?? 'Unknown'
              : 'Unknown'
          ..thumbnailUrl = (r['thumbnails'] as List?)?.isNotEmpty == true
              ? (r['thumbnails'] as List).last['url']?.toString() ?? ''
              : ''
          ..durationMs = (int.tryParse(r['duration']?.toString() ?? '180') ?? 180) * 1000
          ..trackType = 'extractor';

        final norm = normalize(t.title);
        if (!seenTitles.contains(norm)) {
          tracks.add(t);
          seenTitles.add(norm);
        }
      }
      if (tracks.isNotEmpty) return tracks;
    } catch (e) {
      print('[Extractor] getSimilarTracks stage1 error: $e');
    }

    // Stage 2: Artist search fallback
    if (artistName != null && artistName.isNotEmpty) {
      try {
        final results = await search(artistName);
        String normalize(String s) =>
            s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
        final currentNorm = normalize(currentTitle ?? '');
        final seenTitles = <String>{};
        if (currentNorm.isNotEmpty) seenTitles.add(currentNorm);

        final unique = <Track>[];
        for (final t in results) {
          final norm = normalize(t.title);
          if (t.youtubeId != id && !seenTitles.contains(norm)) {
            unique.add(t);
            seenTitles.add(norm);
          }
        }
        return unique.take(15).toList();
      } catch (e) {
        print('[Extractor] getSimilarTracks stage2 error: $e');
      }
    }
    return [];
  }

  // ─── Stream URL ──────────────────────────────────────────────────────────

  @override
  Future<String?> getStreamUrl(String id) async {
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
            print('[Extractor] Stream via InnerTube Android (Instant): $bestUrl');
            if (kIsWeb) {
              return '/api/stream?url=${Uri.encodeComponent(bestUrl)}';
            }
            return bestUrl;
          }
        }
      }
    } catch (e) {
      print('[Extractor] InnerTube Native API failed: $e');
    }

    // Stage 2: Open-Source Concurrent Proxy Resolver (Handles ciphered tracks instantly)
    print('[Extractor] InnerTube failed/ciphered. Firing concurrent proxy requests...');
    final List<String> activeMirrors = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.in.projectsegfau.lt',
      'https://pipedapi.adminforge.de',
      'https://pipedapi.tokhmi.xyz',
      'https://pipedapi.lunar.icu',
      'https://pipedapi.smnz.de',
      'https://piped-api.garudalinux.org',
    ];

    try {
      // Create a Completer to resolve on the FIRST success, or throw only if ALL fail.
      final completer = Completer<String?>();
      int errors = 0;
      
      final futures = activeMirrors.map((mirror) async {
        final res = await _dio.get(
          '$mirror/streams/$id',
          options: Options(
            receiveTimeout: const Duration(milliseconds: 3000),
            sendTimeout: const Duration(milliseconds: 3000),
          ),
        );
        if (res.statusCode == 200) {
          final List audioStreams = res.data['audioStreams'] ?? [];
          if (audioStreams.isNotEmpty) {
            String? best;
            int bestBitrate = 0;
            for (final s in audioStreams) {
              final bitrate = (s['bitrate'] as num?)?.toInt() ?? 0;
              if (bitrate > bestBitrate) {
                bestBitrate = bitrate;
                best = s['url']?.toString();
              }
            }
            if (best != null) return best;
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
      if (fastestUrl != null) {
        print('[Extractor] Stream via Concurrent Proxy: $fastestUrl');
        return fastestUrl;
      }
    } catch (e) {
      print('[Extractor] All concurrent proxies failed: $e');
    }

    // Stage 3: yt-dlp native process fallback (Most reliable, but slowest)
    if (!kIsWeb) {
      await _ensureBinaryExists();
      if (_binary != null && await _binary!.exists()) {
        try {
          final res = await Process.run(_binary!.path, [
            '--no-playlist',
            '--youtube-skip-dash-manifest',
            '--get-url',
            '-f', 'ba[ext=m4a]/ba/bestaudio',
            'https://youtube.com/watch?v=$id',
          ]);

          if (res.exitCode == 0) {
            final url = (res.stdout as String).trim();
            if (url.isNotEmpty) {
              print('[Extractor] Stream via yt-dlp');
              return url;
            }
          }
        } catch (e) {
          print('[Extractor] yt-dlp process error: $e');
        }
      }
    }
    
    return null;
  }

  // ─── Lyrics ──────────────────────────────────────────────────────────────

  @override
  Future<String?> getLyrics(String id) async {
    // Stage 1: Get track title to improve LRCLib search accuracy
    String searchTitle = id;
    String searchArtist = '';

    try {
      final yt = await YTMusic.create();
      final results = await yt.search(id.length < 12 ? id : 'https://youtube.com/watch?v=$id',
          filter: SearchFilter.songs);
      // Try to find the track by videoId
      for (final r in results) {
        if (r['videoId']?.toString() == id) {
          searchTitle = r['title']?.toString() ?? id;
          final artists = r['artists'] as List?;
          searchArtist = artists?.isNotEmpty == true ? artists!.first['name']?.toString() ?? '' : '';
          break;
        }
      }
    } catch (_) {}

    // Stage 2: LRCLib synced lyrics search
    try {
      final query = searchArtist.isNotEmpty
          ? '$searchTitle $searchArtist'
          : searchTitle.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();

      final res = await _dio.get(
        'https://lrclib.net/api/search',
        queryParameters: {'q': query},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );

      if (res.statusCode == 200) {
        final items = res.data as List;
        if (items.isNotEmpty) {
          // Prefer items with synced lyrics
          for (final item in items) {
            final synced = item['syncedLyrics']?.toString();
            if (synced != null && synced.isNotEmpty) return synced;
          }
          // Fallback to plain lyrics
          final plain = items.first['plainLyrics']?.toString();
          if (plain != null && plain.isNotEmpty) return plain;
        }
      }
    } catch (e) {
      print('[Extractor] LRCLib lyrics error: $e');
    }

    // Stage 3: Try yt-dlp for subtitle/lyrics extraction
    try {
      await _ensureBinaryExists();
      if (_binary != null && await _binary!.exists()) {
        final titleRes = await Process.run(
          _binary!.path, ['-O', '%(title)s', 'https://youtube.com/watch?v=$id'],
        );
        if (titleRes.exitCode == 0) {
          final title = (titleRes.stdout as String)
              .trim()
              .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
              .trim();
          final res = await _dio.get(
            'https://lrclib.net/api/search',
            queryParameters: {'q': title},
          );
          if (res.statusCode == 200) {
            final items = res.data as List;
            if (items.isNotEmpty) {
              return items.first['syncedLyrics']?.toString() ??
                  items.first['plainLyrics']?.toString();
            }
          }
        }
      }
    } catch (e) {
      print('[Extractor] yt-dlp lyrics fallback error: $e');
    }

    return null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _decodeHtml(String input) {
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

  /// Downloads a track natively using yt-dlp with real-time progress
  Future<void> downloadTrackNative(
      String videoId, String savePath, Function(double) onProgress) async {
    await _ensureBinaryExists();
    if (_binary == null || !await _binary!.exists()) {
      throw Exception('[Extractor] yt-dlp binary missing');
    }

    final process = await Process.start(_binary!.path, [
      '--progress',
      '--newline',
      '-f', 'bestaudio[ext=m4a]/bestaudio',
      '--embed-metadata',
      '--embed-thumbnail',
      '-o', savePath,
      'https://youtube.com/watch?v=$videoId',
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
      throw Exception('[Extractor] download failed (exit $exitCode): $error');
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
            ..type = 'extractor';
          
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
  Future<List<Track>> searchEpisodes(String query) async {
    final List<Track> tracks = [];
    try {
      final yt = await YTMusic.create();
      final results = await yt.search(query, filter: SearchFilter.episodes);
      
      for (var j in results) {
          if (j['videoId'] == null) continue;
          final t = Track();
          t.youtubeId = j['videoId'].toString();
          t.id = j['videoId'].toString();
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
          t.trackType = 'extractor';
          tracks.add(t);
      }
    } catch(e) {
       print("YTMusicAPI episodes search error: $e");
    }
    return tracks;
  }

  @override
  void dispose() {
    _dio.close();
  }
}
