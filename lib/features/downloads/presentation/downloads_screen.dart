import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/download_task.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/section_header.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadManagerProvider);
    final songs = ref.watch(catalogSongsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SectionHeader(
          title: 'Downloads',
          subtitle:
              'Travel mode, predictive caching, and queue controls built for flaky networks.',
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            FilledButton.icon(
              onPressed: () =>
                  ref.read(downloadManagerProvider).enableTravelMode(songs),
              icon: const Icon(Icons.luggage_rounded),
              label: const Text('Download library for travel'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(downloadManagerProvider)
                  .precacheSongs(songs.take(10).toList()),
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('Warm next 10 songs'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...downloads.tasks.map((DownloadTask task) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DesiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              task.subtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Chip(label: Text(task.format)),
                      const SizedBox(width: 8),
                      Chip(label: Text(task.status.name)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: task.progress),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: () => ref
                            .read(downloadManagerProvider)
                            .togglePause(task.id),
                        child: Text(
                          task.status == DownloadStatus.paused
                              ? 'Resume'
                              : 'Pause',
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(downloadManagerProvider)
                            .redownload(task.id),
                        child: const Text('Re-download'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(downloadManagerProvider)
                            .removeTask(task.id),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
