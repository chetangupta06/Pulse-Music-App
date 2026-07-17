import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/demo_seed.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/song_card.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(filteredSongsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger a simple UI rebuild or provider refresh
        ref.invalidate(filteredSongsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          SectionHeader(
            title: query.isEmpty ? 'Discover Desi Depth' : 'Results for "$query"',
            subtitle: query.isEmpty
                ? 'Search by mood, language, ritual, or even a rainy-night feeling.'
                : '${results.length} local matches across your visible catalog.',
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Discover',
              onPressed: () {
                ref.invalidate(filteredSongsProvider);
              },
            ),
          ),
          const SizedBox(height: 18),
          if (results.isEmpty && query.isNotEmpty)
            const DesiCard(
              child: Text(
                'No close matches yet. Try a language, a singer, or a festival mood like "garba" or "bhakti".',
              ),
            )
          else if (query.isNotEmpty)
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: results
                  .map(
                    (song) => SizedBox(
                      width: 250,
                      height: 300,
                      child: SongCard(song: song, queue: results, compact: true),
                    ),
                  )
                  .toList(),
            )
          else ...<Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const <String>[
                'Sad songs',
                'Latest Arijit',
                'Tamil drive',
                'Bhakti calm',
                'Wedding dance',
                'Rainy ghazal',
              ].map((String suggestion) {
                return ActionChip(label: Text(suggestion), onPressed: null);
              }).toList(),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Artist Stories',
              subtitle:
                  'Quick cultural context with Hindi and English-ready summaries.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: DemoSeed.artistStories.map((story) {
                return SizedBox(
                  width: 320,
                  child: DesiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          story.artist,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          story.storyEn,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          story.storyHi,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
