import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/song.dart';
import '../../core/providers/app_providers.dart';
import '../../utils/formatters.dart';
import 'desi_card.dart';

class SongCard extends ConsumerWidget {
  const SongCard({
    super.key,
    required this.song,
    this.queue,
    this.compact = false,
  });

  final Song song;
  final List<Song>? queue;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final library = ref.watch(libraryRepositoryProvider);
    final isFavorite = library.isFavorite(song.id);

    return DesiCard(
      onTap: () =>
          ref.read(playbackControllerProvider).playSong(song, queue: queue),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: song.palette),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton.filledTonal(
                      onPressed: () => ref
                          .read(libraryRepositoryProvider)
                          .toggleFavorite(song.id),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            song.album,
                            maxLines: 2,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: compact ? 18 : 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: compact ? 22 : 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${song.artist} - ${song.language} - ${formatDuration(song.duration)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(label: Text(song.mood)),
              Chip(label: Text(song.genre)),
              Chip(label: Text(song.bitrateLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
