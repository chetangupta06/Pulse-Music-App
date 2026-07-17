import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/song_card.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(catalogSongsProvider);
    final library = ref.watch(libraryRepositoryProvider);
    final favorites = library.favorites(songs);
    final recent = library.recentlyPlayed(songs);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SectionHeader(
          title: 'Your Library',
          subtitle:
              'Favorites, recent history, and saved mixes that stay local to this guest device.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: <Widget>[
            SizedBox(
              width: 280,
              child: DesiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Favorite songs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${favorites.length}',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: DesiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent plays',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${recent.length}',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: DesiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Saved playlists',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${library.playlists.length}',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Favorites',
          subtitle: 'One-tap access to the tracks you keep coming back to.',
        ),
        const SizedBox(height: 18),
        if (favorites.isEmpty)
          const DesiCard(
            child: Text(
              'No favorites yet. Tap the heart on any song card to pin it here.',
            ),
          )
        else
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: favorites
                .map(
                  (song) => SizedBox(
                    width: 250,
                    height: 300,
                    child: SongCard(song: song, queue: favorites),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Recently Played',
          subtitle:
              'History-backed recall so desktop sessions feel continuous.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: recent
              .map(
                (song) => SizedBox(
                  width: 250,
                  height: 300,
                  child: SongCard(song: song, queue: recent),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
