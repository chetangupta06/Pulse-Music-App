import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/desi_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/song_card.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryRepositoryProvider);
    final songs = ref.watch(catalogSongsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SectionHeader(
          title: 'Playlists',
          subtitle:
              'Import from YouTube Music links, save AI mixes, and keep it all local-first.',
        ),
        const SizedBox(height: 18),
        DesiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Paste a YouTube Music or YouTube share link',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  final playlist = ref
                      .read(libraryRepositoryProvider)
                      .importPlaylistLink(_controller.text, songs);
                  final message = playlist == null
                      ? 'That link did not look like a YouTube Music share link.'
                      : 'Imported ${playlist.title} into your local playlists.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                },
                icon: const Icon(Icons.link_rounded),
                label: const Text('Import Playlist'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...library.playlists.map((playlist) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: DesiCard(
              gradient: LinearGradient(colors: playlist.gradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    playlist.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: playlist.songs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (_, int index) => SizedBox(
                        width: 230,
                        child: SongCard(
                          song: playlist.songs[index],
                          queue: playlist.songs,
                        ),
                      ),
                    ),
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
