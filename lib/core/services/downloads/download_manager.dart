import 'package:flutter/foundation.dart';

import '../../models/download_task.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';

class DownloadManager extends ChangeNotifier {
  DownloadManager({required List<DownloadTask> initialTasks})
      : _tasks = <DownloadTask>[...initialTasks];

  final List<DownloadTask> _tasks;

  List<DownloadTask> get tasks => List<DownloadTask>.unmodifiable(_tasks);

  void queueSong(Song song) {
    if (_tasks.any((DownloadTask task) => task.title == song.title)) {
      return;
    }
    _tasks.insert(
      0,
      DownloadTask(
        id: 'song-${song.id}',
        title: song.title,
        subtitle: '${song.artist} - guest-mode offline download',
        progress: 0,
        status: DownloadStatus.queued,
        format: '.opus',
        syncedLyricsEmbedded: true,
      ),
    );
    notifyListeners();
  }

  void queuePlaylist(Playlist playlist) {
    _tasks.insert(
      0,
      DownloadTask(
        id: 'playlist-${playlist.id}',
        title: playlist.title,
        subtitle: 'Batch download - ${playlist.songs.length} tracks',
        progress: 0.12,
        status: DownloadStatus.downloading,
        format: '.m4a',
        syncedLyricsEmbedded: true,
      ),
    );
    notifyListeners();
  }

  void precacheSongs(List<Song> songs) {
    _tasks.insert(
      0,
      DownloadTask(
        id: 'predictive-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Predictive cache',
        subtitle: 'Pre-warming the next ${songs.take(10).length} songs',
        progress: 0.3,
        status: DownloadStatus.cached,
        format: '.cache',
        syncedLyricsEmbedded: false,
      ),
    );
    notifyListeners();
  }

  void enableTravelMode(List<Song> songs) {
    _tasks.insert(
      0,
      DownloadTask(
        id: 'travel-mode',
        title: 'Travel mode library',
        subtitle: 'Queued ${songs.length} songs for offline use',
        progress: 0.06,
        status: DownloadStatus.downloading,
        format: '.m4a',
        syncedLyricsEmbedded: true,
      ),
    );
    notifyListeners();
  }

  void togglePause(String id) {
    final index = _tasks.indexWhere((DownloadTask task) => task.id == id);
    if (index == -1) {
      return;
    }
    final task = _tasks[index];
    final nextStatus = task.status == DownloadStatus.paused
        ? DownloadStatus.downloading
        : DownloadStatus.paused;
    _tasks[index] = task.copyWith(status: nextStatus);
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((DownloadTask task) => task.id == id);
    notifyListeners();
  }

  void redownload(String id) {
    final index = _tasks.indexWhere((DownloadTask task) => task.id == id);
    if (index == -1) {
      return;
    }
    final task = _tasks[index];
    _tasks[index] = task.copyWith(
      progress: 0.1,
      status: DownloadStatus.downloading,
    );
    notifyListeners();
  }
}
