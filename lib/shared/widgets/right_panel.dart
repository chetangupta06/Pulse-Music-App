import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../utils/formatters.dart';
import 'desi_card.dart';

class RightPanel extends ConsumerWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(rightPanelTabProvider);
    final playback = ref.watch(playbackControllerProvider);
    final community = ref.watch(communityServiceProvider);
    final lyricsTranslation = ref.watch(lyricsTranslationProvider);
    final currentSong = playback.currentSong;
    final library = ref.watch(libraryRepositoryProvider);

    final tabs = <String>['Queue', 'Lyrics', 'Similar', 'Live'];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.52),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(
              tabs.length,
              (int index) => ChoiceChip(
                selected: tab == index,
                label: Text(tabs[index]),
                onSelected: (_) =>
                    ref.read(rightPanelTabProvider.notifier).state = index,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: switch (tab) {
              0 => ListView.separated(
                  itemCount: playback.queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final item = playback.queue[index];
                    final active = index == playback.currentIndex;
                    return DesiCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => ref
                          .read(playbackControllerProvider)
                          .playSong(item, queue: playback.queue),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: item.palette.first.withValues(
                              alpha: 0.18,
                            ),
                            child: Icon(
                              active
                                  ? Icons.graphic_eq_rounded
                                  : Icons.music_note_rounded,
                              color: item.palette.first,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(formatDuration(item.duration)),
                        ],
                      ),
                    );
                  },
                ),
              1 => currentSong == null
                  ? const Center(
                      child: Text('Play a song to see synced lyrics.'),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Synced lyrics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => ref
                                  .read(
                                    lyricsTranslationProvider.notifier,
                                  )
                                  .state = !lyricsTranslation,
                              icon: Icon(
                                lyricsTranslation
                                    ? Icons.translate_rounded
                                    : Icons.g_translate_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: currentSong.lyrics.length,
                            itemBuilder: (BuildContext context, int index) {
                              final line = currentSong.lyrics[index];
                              final active = playback.position >= line.time &&
                                  (index == currentSong.lyrics.length - 1 ||
                                      playback.position <
                                          currentSong.lyrics[index + 1].time);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Text(
                                  lyricsTranslation
                                      ? (line.translation ?? line.text)
                                      : line.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: active
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
              2 => ListView.separated(
                  itemCount: playback.similarSongs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final item = playback.similarSongs[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.52),
                      title: Text(item.title),
                      subtitle: Text('${item.artist} - ${item.genre}'),
                      trailing: const Icon(Icons.play_circle_fill_rounded),
                      onTap: () => ref
                          .read(playbackControllerProvider)
                          .playSong(item, queue: playback.similarSongs),
                    );
                  },
                ),
              _ => ListView(
                  children: <Widget>[
                    DesiCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Live collaborators',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: library.playlists.first.members
                                .map((String member) =>
                                    Chip(label: Text(member)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...community.activityFeed.map(
                      (String activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DesiCard(
                          padding: const EdgeInsets.all(14),
                          child: Text(activity),
                        ),
                      ),
                    ),
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}
