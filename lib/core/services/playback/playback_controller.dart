import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/song.dart';
import '../audio/rust_audio_bridge.dart';
import '../discovery/discovery_engine.dart';
import '../library/library_repository.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required LibraryRepository libraryRepository,
    required DiscoveryEngine discoveryEngine,
    required List<Song> catalog,
    RustAudioBridge? rustAudioBridge,
  })  : _libraryRepository = libraryRepository,
        _discoveryEngine = discoveryEngine,
        _catalog = catalog,
        _rustAudioBridge = rustAudioBridge ?? const RustAudioBridge() {
    _queue = catalog.take(6).toList();
    _positionSubscription = _player.positionStream.listen(_handlePosition);
    _durationSubscription = _player.durationStream.listen(_handleDuration);
    _playerStateSubscription =
        _player.playerStateStream.listen(_handlePlayerState);
  }

  static const String _demoAssetPath = 'assets/audio/desi_demo_loop.wav';

  final LibraryRepository _libraryRepository;
  final DiscoveryEngine _discoveryEngine;
  final List<Song> _catalog;
  final RustAudioBridge _rustAudioBridge;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _sleepTimer;

  List<Song> _queue = <Song>[];
  int _currentIndex = 0;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  bool _spatialAudioEnabled = false;
  bool _radioModeEnabled = true;
  bool _karaokeModeEnabled = false;
  bool _skipSilenceEnabled = true;
  double _crossfadeSeconds = 4;
  String _equalizerPreset = 'Carvaan Vintage';
  String? _audioError;
  DateTime? _sleepDeadline;

  List<Song> get queue => List<Song>.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Duration get position => _position;
  Duration get totalDuration => _totalDuration > Duration.zero
      ? _totalDuration
      : currentSong?.duration ?? Duration.zero;
  bool get isPlaying => _isPlaying;
  bool get isLoadingAudio => _isLoadingAudio;
  bool get spatialAudioEnabled => _spatialAudioEnabled;
  bool get radioModeEnabled => _radioModeEnabled;
  bool get karaokeModeEnabled => _karaokeModeEnabled;
  bool get skipSilenceEnabled => _skipSilenceEnabled;
  double get crossfadeSeconds => _crossfadeSeconds;
  String get equalizerPreset => _equalizerPreset;
  String get audioSourceLabel =>
      _audioError == null ? 'Demo audio' : 'Audio issue';
  DateTime? get sleepDeadline => _sleepDeadline;
  Song? get currentSong => _queue.isEmpty ? null : _queue[_currentIndex];

  List<Song> get similarSongs {
    final current = currentSong;
    if (current == null) {
      return const <Song>[];
    }
    return _discoveryEngine.relatedSongs(current, _catalog);
  }

  Map<String, double> get equalizerProfile {
    return _rustAudioBridge.profileForPreset(_equalizerPreset);
  }

  void playSong(Song song, {List<Song>? queue}) {
    final targetQueue = queue == null || queue.isEmpty ? <Song>[song] : queue;
    _queue = List<Song>.from(targetQueue);
    _currentIndex = _queue.indexWhere(
      (Song candidate) => candidate.id == song.id,
    );
    if (_currentIndex < 0) {
      _currentIndex = 0;
    }

    _position = Duration.zero;
    _audioError = null;
    _libraryRepository.recordPlayback(song);
    notifyListeners();
    unawaited(_loadCurrentSongAudio(autoPlay: true));
  }

  void togglePlayPause() {
    if (currentSong == null) {
      return;
    }

    if (_player.audioSource == null) {
      unawaited(_loadCurrentSongAudio(autoPlay: true));
      return;
    }

    if (_player.playing) {
      unawaited(_player.pause());
    } else {
      unawaited(_player.play());
    }
  }

  void seek(Duration position) {
    final total = totalDuration;
    if (total == Duration.zero) {
      return;
    }

    final clamped = position > total ? total : position;
    _position = clamped;
    notifyListeners();
    unawaited(_player.seek(clamped));
  }

  void next() {
    unawaited(_skipToNext());
  }

  void previous() {
    if (_queue.isEmpty) {
      return;
    }

    if (_position.inSeconds > 4) {
      _position = Duration.zero;
      notifyListeners();
      unawaited(_player.seek(Duration.zero));
      return;
    }

    unawaited(_skipToPrevious());
  }

  void setCrossfade(double value) {
    _crossfadeSeconds = value;
    notifyListeners();
  }

  void toggleSpatialAudio() {
    _spatialAudioEnabled = !_spatialAudioEnabled;
    notifyListeners();
  }

  void toggleRadioMode() {
    _radioModeEnabled = !_radioModeEnabled;
    notifyListeners();
  }

  void toggleKaraokeMode() {
    _karaokeModeEnabled = !_karaokeModeEnabled;
    notifyListeners();
  }

  void toggleSkipSilence() {
    _skipSilenceEnabled = !_skipSilenceEnabled;
    notifyListeners();
  }

  void setEqualizerPreset(String preset) {
    _equalizerPreset = preset;
    notifyListeners();
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepDeadline = duration == null ? null : DateTime.now().add(duration);

    if (duration != null) {
      _sleepTimer = Timer(duration, () async {
        _sleepDeadline = null;
        _isPlaying = false;
        notifyListeners();
        await _player.pause();
      });
    }

    notifyListeners();
  }

  String handleVoiceCommand(String command) {
    final normalized = command.toLowerCase();
    Song? selected;

    if (normalized.contains('arijit')) {
      selected = _catalog.firstWhere(
        (Song song) => song.artist.contains('Arijit'),
      );
    } else if (normalized.contains('punjabi')) {
      selected = _catalog.firstWhere((Song song) => song.language == 'Punjabi');
    } else if (normalized.contains('bhakti') || normalized.contains('shiv')) {
      selected = _catalog.firstWhere((Song song) => song.genre == 'Bhakti');
    } else if (normalized.contains('rain')) {
      selected = _catalog.firstWhere((Song song) => song.mood == 'Rain');
    } else if (_catalog.isNotEmpty) {
      selected = _catalog.first;
    }

    if (selected == null) {
      return 'No close match found.';
    }

    playSong(
      selected,
      queue: <Song>[
        selected,
        ..._discoveryEngine.relatedSongs(selected, _catalog),
      ],
    );
    return 'Playing ${selected.title} by ${selected.artist}.';
  }

  Future<void> _skipToNext() async {
    if (_queue.isEmpty) {
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_radioModeEnabled && currentSong != null) {
      final additions = _discoveryEngine
          .relatedSongs(currentSong!, _catalog)
          .where(
            (Song song) =>
                _queue.every((Song existing) => existing.id != song.id),
          )
          .take(3)
          .toList();
      if (additions.isNotEmpty) {
        _queue = <Song>[..._queue, ...additions];
        _currentIndex++;
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        _totalDuration = Duration.zero;
        notifyListeners();
        await _player.stop();
        return;
      }
    } else {
      _isPlaying = false;
      _position = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
      await _player.stop();
      return;
    }

    final song = currentSong;
    if (song != null) {
      _libraryRepository.recordPlayback(song);
    }
    _position = Duration.zero;
    notifyListeners();
    await _loadCurrentSongAudio(autoPlay: true);
  }

  Future<void> _skipToPrevious() async {
    if (_queue.isEmpty) {
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    }
    _position = Duration.zero;
    notifyListeners();
    await _loadCurrentSongAudio(autoPlay: true);
  }

  Future<void> _loadCurrentSongAudio({required bool autoPlay}) async {
    final song = currentSong;
    if (song == null) {
      return;
    }

    _isLoadingAudio = true;
    _audioError = null;
    notifyListeners();

    try {
      await _player.setLoopMode(LoopMode.off);
      await _player.setAsset(_demoAssetPath);
      _totalDuration = _player.duration ?? song.duration;
      _position = Duration.zero;

      if (autoPlay) {
        await _player.play();
      } else {
        await _player.pause();
      }
    } catch (error, stackTrace) {
      debugPrint('Audio failed to load: $error');
      debugPrintStack(stackTrace: stackTrace);
      _audioError = 'Unable to load demo audio';
      _isPlaying = false;
    } finally {
      _isLoadingAudio = false;
      notifyListeners();
    }
  }

  void _handlePosition(Duration nextPosition) {
    if (nextPosition.inSeconds == _position.inSeconds) {
      return;
    }
    _position = nextPosition;
    notifyListeners();
  }

  void _handleDuration(Duration? duration) {
    final nextDuration = duration ?? Duration.zero;
    if (nextDuration == _totalDuration) {
      return;
    }
    _totalDuration = nextDuration;
    notifyListeners();
  }

  void _handlePlayerState(PlayerState state) {
    final nextPlaying =
        state.playing && state.processingState != ProcessingState.completed;
    if (_isPlaying != nextPlaying) {
      _isPlaying = nextPlaying;
      notifyListeners();
    }

    if (state.processingState == ProcessingState.completed) {
      next();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }
}
