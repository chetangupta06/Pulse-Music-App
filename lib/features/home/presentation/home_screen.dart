import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/demo_seed.dart';
import '../../../core/models/song.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/hero_banner_carousel.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/song_card.dart';
import '../../../shared/widgets/status_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(discoveryEngineProvider);
    final library = ref.watch(libraryRepositoryProvider);
    final downloads = ref.watch(downloadManagerProvider);
    final festivals = ref.watch(festivalEventsProvider);

    final trending = discovery.trending(DemoSeed.songs);
    final madeForYou = discovery.madeForYou(DemoSeed.songs);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        HeroBannerCarousel(playlists: DemoSeed.playlists, festivals: festivals),
        const SizedBox(height: 24),
        SizedBox(
          height: 188,
          child: Row(
            children: <Widget>[
              Expanded(
                child: MetricCard(
                  label: 'Guest Library',
                  value: '${DemoSeed.songs.length} songs',
                  caption:
                      'Instant search across Bollywood, bhakti, and regional moods.',
                  icon: Icons.library_music_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  label: 'Favorites',
                  value: '${library.favoriteSongIds.length}',
                  caption: 'Pinned for quick access without any account.',
                  icon: Icons.favorite_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DownloadSummaryCard(
                  completed: downloads.tasks
                      .where((task) => task.progress >= 1)
                      .length,
                  queued:
                      downloads.tasks.where((task) => task.progress < 1).length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Trending India',
          subtitle:
              'Fast-glance momentum across the most-loved desi moods right now.',
        ),
        const SizedBox(height: 18),
        _SongRail(songs: trending),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Made For You',
          subtitle:
              'Gentle local recommendations built from language, vibe, and recent picks.',
        ),
        const SizedBox(height: 18),
        _SongRail(songs: madeForYou),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Carvaan Stations',
          subtitle:
              'Lean-back stations for artistes, moods, and festival rituals.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: DemoSeed.stations.take(4).map((station) {
            return SizedBox(
              width: 250,
              child: DesiCard(
                gradient: LinearGradient(colors: station.palette),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      station.category.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                    const Spacer(),
                    Text(
                      station.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      station.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Artist Story Cards',
          subtitle:
              'Context-rich listening for users who love a little music history with the song.',
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
                    const SizedBox(height: 6),
                    Text(
                      story.headline,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    ...story.facts.map(
                      (String fact) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('- $fact'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SongRail extends StatelessWidget {
  const _SongRail({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            width: 250,
            child: SongCard(song: songs[index], queue: List<Song>.of(songs)),
          );
        },
      ),
    );
  }
}
