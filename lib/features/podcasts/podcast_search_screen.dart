import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/podcast_service.dart';
import '../../core/providers.dart';
import '../../core/models/app_playlist.dart';
import '../../core/models/track.dart';
import '../../shared/widgets/hover_container.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../playlist/playlist_screen.dart';

final podcastSearchQueryProvider = StateProvider<String>((ref) => '');

final podcastSearchEpisodesProvider = FutureProvider<List<Track>>((ref) async {
  final query = ref.watch(podcastSearchQueryProvider);
  if (query.isEmpty) return [];
  final ytService = ref.read(ytdlpServiceProvider) as dynamic;
  return await ytService.searchEpisodes(query);
});

final podcastSearchPlaylistsProvider = FutureProvider<List<AppPlaylist>>((ref) async {
  final query = ref.watch(podcastSearchQueryProvider);
  if (query.isEmpty) return [];
  final ytService = ref.read(ytdlpServiceProvider) as dynamic;
  return await ytService.searchPodcasts(query);
});

class PodcastSearchScreen extends ConsumerStatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  ConsumerState<PodcastSearchScreen> createState() => _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends ConsumerState<PodcastSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search for podcasts & episodes...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          onSubmitted: (val) {
            ref.read(podcastSearchQueryProvider.notifier).state = val;
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _buildPodcastsResults(ref),
          _buildEpisodesResults(ref),
        ],
      ),
    );
  }

  Widget _buildPodcastsResults(WidgetRef ref) {
    final asyncPodcasts = ref.watch(podcastSearchPlaylistsProvider);
    
    return asyncPodcasts.when(
      data: (podcasts) {
        if (podcasts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text("Podcasts", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: podcasts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 24),
                  itemBuilder: (context, index) {
                    final p = podcasts[index];
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: p))),
                        child: SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(p.thumbnailUrl, width: 160, height: 160, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 160, height: 160, child: Icon(Icons.mic, size: 48))),
                              ),
                              const SizedBox(height: 12),
                              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(p.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, st) => SliverToBoxAdapter(child: Text("Error: $e")),
    );
  }

  Widget _buildEpisodesResults(WidgetRef ref) {
    final asyncEpisodes = ref.watch(podcastSearchEpisodesProvider);
    
    return asyncEpisodes.when(
      data: (episodes) {
        if (episodes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                 return Padding(
                   padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                   child: Text("Episodes", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                 );
              }
              final t = episodes[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: HoverContainer(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(t.effectiveThumbnailUrl, width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${t.artist} • ${(t.durationMs / 60000).ceil()} mins", maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: TrackContextMenu(track: t, child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    onTap: () {
                      ref.read(queueProvider.notifier).playAll(episodes, startIndex: index - 1);
                    },
                  ),
                ),
              );
            },
            childCount: episodes.length + 1,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
