enum DownloadStatus { queued, downloading, paused, completed, cached }

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.status,
    required this.format,
    required this.syncedLyricsEmbedded,
  });

  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final DownloadStatus status;
  final String format;
  final bool syncedLyricsEmbedded;

  DownloadTask copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? progress,
    DownloadStatus? status,
    String? format,
    bool? syncedLyricsEmbedded,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      format: format ?? this.format,
      syncedLyricsEmbedded: syncedLyricsEmbedded ?? this.syncedLyricsEmbedded,
    );
  }
}
