import 'package:media_kit/media_kit.dart' hide Track;
import '../models/track.dart';

import 'package:flutter/foundation.dart';

/// VLC-backed audio player — bypasses Windows Media Foundation entirely.
class DesiAudioHandler {
  final Player _player = Player();
  Player get player => _player;
  Function()? onCompleted;

  DesiAudioHandler() {
    // Advanced VLC/MPV flags for instantaneous playback starts and gapless buffering
    if (!kIsWeb && _player.platform is NativePlayer) {
      final p = _player.platform as dynamic;
      p.setProperty('cache', 'yes');
      p.setProperty('demuxer-max-bytes', '51200000'); // 50MB
      p.setProperty('demuxer-readahead-secs', '30');
      p.setProperty('network-timeout', '10');
      // Low-latency flags for faster manual click start
      p.setProperty('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      p.setProperty('http-header-fields', 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    }

    _player.stream.completed.listen((completed) {
      if (completed) {
        print('Track completed naturally.');
        onCompleted?.call();
      }
    });

    _player.stream.error.listen((err) {
      print('MEDIA_KIT ENGINE ERROR: $err');
    });
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  /// Opens a track instantly and provides the ability to append the next track later for gapless transitions
  Future<void> playTrack(Track track, String streamingUrl) async {
    try {
      print('ENGINE OPENING: $streamingUrl');
      await _player.open(Media(streamingUrl), play: true);
    } catch (e) {
      print('MEDIA_KIT PLAYBACK EXCEPTION: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
