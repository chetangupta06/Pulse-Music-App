import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulse/core/models/track.dart';
import 'package:pulse/core/api/music_service.dart';
import 'package:pulse/core/api/youtube_dlp_service.dart';
import 'package:pulse/core/db/isar_db.dart';
import 'package:pulse/core/providers.dart';

class DownloadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
  ));
  final MusicService _api;
  final IsarDb _db;
  final Ref _ref;

  DownloadService(this._api, this._db, this._ref);

  Future<void> startDownload(Track track) async {
    _ref.read(downloadProgressProvider.notifier).setProgress(track.youtubeId, 0.01);
    
    try {
      final url = await _api.getStreamUrl(track.youtubeId);
      if (url == null) {
        _ref.read(downloadProgressProvider.notifier).setError(track.youtubeId);
        return;
      }

      if (kIsWeb) {
        final parsedUrl = Uri.tryParse(url);
        if (parsedUrl != null) {
          await launchUrl(parsedUrl, mode: LaunchMode.externalApplication);
          _ref.read(downloadProgressProvider.notifier).setCompleted(track.youtubeId);
          // Don't save to Isar DB as local path for Web
        } else {
          _ref.read(downloadProgressProvider.notifier).setError(track.youtubeId);
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('download_path');
      
      late Directory desiDir;
      if (customPath != null && customPath.isNotEmpty) {
        desiDir = Directory(customPath);
      } else {
        final extDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        desiDir = Directory('${extDir.path}/PULSE');
      }
      
      if (!await desiDir.exists()) {
        await desiDir.create(recursive: true);
      }

      final safeTitle = track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
      final savePath = '${desiDir.path}/$safeTitle.m4a';
      
      print('Downloading to: $savePath');

      // Use native yt-dlp downloader for YouTube/Extractor tracks to prevent 403 Forbidden errors
      if (track.trackType == 'youtube' || track.trackType == 'extractor' || track.trackType == 'history') {
        final ytService = _ref.read(ytdlpServiceProvider);
        await ytService.downloadTrackNative(track.youtubeId, savePath, (p) {
          _ref.read(downloadProgressProvider.notifier).setProgress(track.youtubeId, p);
        });
      } else {
        // Fallback for direct streams or other sources
        await _dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              _ref.read(downloadProgressProvider.notifier).setProgress(track.youtubeId, received / total);
            }
          },
        );
      }

      print('Download complete: $savePath');

      track.isDownloaded = true;
      track.localPath = savePath;
      await _db.saveTrack(track);

      _ref.read(downloadProgressProvider.notifier).setCompleted(track.youtubeId);
    } catch (e) {
      print('Download error: $e');
      _ref.read(downloadProgressProvider.notifier).setError(track.youtubeId);
    }
  }
}

class DownloadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    return {"_": 0.0};
  }

  void setProgress(String id, double progress) {
    state = {...state, id: progress};
  }

  void setCompleted(String id) {
    state = {...state, id: 2.0};
  }

  void setError(String id) {
    state = {...state, id: -1.0};
  }

  void clearProgress(String id) {
    final newState = Map<String, double>.from(state);
    newState.remove(id);
    state = newState;
  }
}
