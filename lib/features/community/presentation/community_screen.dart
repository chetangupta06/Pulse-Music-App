import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/section_header.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityServiceProvider);
    final library = ref.watch(libraryRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SectionHeader(
          title: 'Community',
          subtitle:
              'Anonymous sharing, collaborative lists, and a polished yearly wrapped card.',
        ),
        const SizedBox(height: 18),
        DesiCard(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFFF6700),
              Color(0xFFFFB800),
              Color(0xFF5C2500),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'My 2026 Wrapped',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Top mood: Rainy nostalgia\nTop language: Hindi\nTop ritual: Late-night mehfil',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wrapped card prepared for WhatsApp.'),
                      ),
                    ),
                    child: const Text('Share to WhatsApp'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wrapped card prepared for Telegram.'),
                      ),
                    ),
                    child: const Text('Share to Telegram'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wrapped card prepared for Instagram.'),
                      ),
                    ),
                    child: const Text('Share to Instagram'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(
          title: 'Collaborative playlists',
          subtitle:
              'See who joined, who added songs, and which stations the room is pushing upward.',
        ),
        const SizedBox(height: 18),
        ...library.playlists.take(3).map(
              (playlist) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DesiCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              playlist.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.members.join(', ')} - ${playlist.songs.length} songs',
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => ref
                            .read(communityServiceProvider)
                            .joinPlaylist(playlist),
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 18),
        ...community.activityFeed.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DesiCard(
              padding: const EdgeInsets.all(14),
              child: Text(activity),
            ),
          ),
        ),
      ],
    );
  }
}
