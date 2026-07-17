import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:podcast_search/podcast_search.dart';
import '../../core/api/podcast_service.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../shared/widgets/hover_container.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'podcast_detail_screen.dart';
import 'podcast_search_screen.dart';
import '../playlist/playlist_screen.dart';
import '../../core/models/app_playlist.dart';
import '../../core/models/track.dart';
import '../../shared/widgets/track_context_menu.dart';

class PodcastsScreen extends ConsumerWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(settingsProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Podcasts",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ref.invalidate(youtubeRecommendedEpisodesProvider);
                          ref.invalidate(dynamicPodcastProvider);
                          ref.invalidate(dynamicPodcastEpisodesProvider);
                          ref.invalidate(trendingPodcastsProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh Podcasts',
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PodcastSearchScreen())),
                        icon: const Icon(Icons.search_rounded),
                        tooltip: 'Search Podcasts',
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (appSettings.podcastActiveSections.contains('Recommended for You'))
                  _ScrollableSection(title: "Recommended for You", builder: (c) => _buildYoutubeEpisodesRow(context, ref, youtubeRecommendedEpisodesProvider, c)),
                
                if (appSettings.podcastActiveSections.contains('Recommended for You'))
                  const SizedBox(height: 36),
                  
                if (appSettings.podcastActiveSections.contains('Top Trending Global'))
                  _ScrollableSection(title: "Top Trending Global", builder: (c) => _buildTrendingPodcasts(context, ref, c)),
                  
                if (appSettings.podcastActiveSections.contains('Top Trending Global'))
                  const SizedBox(height: 36),

                // Render active default podcast genres dynamically
                ...['Psychology', 'Philosophy', 'Ghost stories']
                    .where((section) => appSettings.podcastActiveSections.contains(section))
                    .map((section) {
                      return Column(
                        children: [
                          _ScrollableSection(title: section, builder: (c) => _buildYoutubePodcastsRow(context, ref, dynamicPodcastProvider("$section podcast"), c)),
                          const SizedBox(height: 36),
                        ],
                      );
                    }).toList(),

                // Render custom podcasters dynamically
                ...appSettings.customPodcasters.map((podcaster) {
                   return Column(
                     children: [
                       _ScrollableSection(title: podcaster, builder: (c) => _buildYoutubePodcastsRow(context, ref, dynamicPodcastProvider("$podcaster podcast"), c)),
                       const SizedBox(height: 24),
                       _ScrollableSection(title: "Episodes by $podcaster", builder: (c) => _buildYoutubeEpisodesRow(context, ref, dynamicPodcastEpisodesProvider("$podcaster podcast"), c)),
                       const SizedBox(height: 36),
                     ],
                   );
                }).toList(),
              ]),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120))
        ],
      ),
    );
  }

  Widget _buildTrendingPodcasts(BuildContext context, WidgetRef ref, ScrollController controller) {
    final trendingAsync = ref.watch(trendingPodcastsProvider);

    return trendingAsync.when(
      data: (podcasts) {
        if (podcasts.isEmpty) return const SizedBox(height: 220, child: Center(child: Text("No podcasts found")));
        return SizedBox(
          height: 220,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: podcasts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              return _PodcastCard(podcast: podcasts[index]);
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 220,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => SizedBox(width: 180, child: SkeletonLoader(child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16))))),
        ),
      ),
      error: (e, st) => const SizedBox(height: 220, child: Center(child: Text("Error fetching trending"))),
    );
  }

  Widget _buildYoutubePodcastsRow(BuildContext context, WidgetRef ref, FutureProvider<List<AppPlaylist>> provider, ScrollController controller) {
    final asyncData = ref.watch(provider);
    return asyncData.when(
      data: (podcasts) {
        if (podcasts.isEmpty) {
          return SizedBox(
            height: 100, 
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 32),
                  const SizedBox(height: 8),
                  Text("No podcasts available", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: podcasts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              final p = podcasts[index];
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: p))),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(p.thumbnailUrl, width: 140, height: 140, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 140, height: 140, child: Icon(Icons.mic, size: 48))),
                        ),
                        const SizedBox(height: 12),
                        Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(p.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 220,
        child: ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => const SizedBox(width: 140, child: SkeletonTrackCard()),
        ),
      ),
      error: (e, st) => const SizedBox(height: 220, child: Center(child: Text("Error fetching category"))),
    );
  }

  Widget _buildYoutubeEpisodesRow(BuildContext context, WidgetRef ref, FutureProvider<List<Track>> provider, ScrollController controller) {
    final asyncData = ref.watch(provider);
    return asyncData.when(
      data: (episodes) {
        if (episodes.isEmpty) {
          return SizedBox(
            height: 100, 
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 32),
                  const SizedBox(height: 8),
                  Text("No episodes available", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 340,
          child: GridView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              mainAxisExtent: 440,
            ),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final t = episodes[index];
              return HoverContainer(
                child: InkWell(
                  onTap: () {
                    ref.read(queueProvider.notifier).playAll(episodes, startIndex: index);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            t.effectiveThumbnailUrl, 
                            width: 160, 
                            height: 90, 
                            fit: BoxFit.cover, 
                            errorBuilder: (_,__,___) => Container(width: 160, height: 90, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.mic, size: 48))
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.durationMs > 0 ? "Podcast Episode • ${(t.durationMs / 60000).ceil()} mins" : "Podcast Episode", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                        TrackContextMenu(track: t, child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => SizedBox(width: 320, child: SkeletonLoader(child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16))))),
        ),
      ),
      error: (e, st) => const SizedBox(height: 140, child: Center(child: Text("Error fetching episodes"))),
    );
  }
}

class _PodcastCard extends StatefulWidget {
  final Item podcast;
  const _PodcastCard({required this.podcast});

  @override
  State<_PodcastCard> createState() => _PodcastCardState();
}

class _PodcastCardState extends State<_PodcastCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.podcast;
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (p.feedUrl != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PodcastDetailScreen(feedUrl: p.feedUrl!)));
          }
        },
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isHovered ? 0.3 : 0.1),
                      blurRadius: isHovered ? 12 : 8,
                      offset: Offset(0, isHovered ? 8 : 4),
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (p.artworkUrl600 != null || p.bestArtworkUrl != null)
                        Image.network(
                          p.bestArtworkUrl ?? p.artworkUrl600!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallback(theme),
                        )
                      else
                        _buildFallback(theme),
                        
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovered ? 1.0 : 0.0,
                        child: Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                p.collectionName ?? 'Podcast',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.artistName ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    return Container(
      color: theme.primaryColor.withOpacity(0.2),
      child: Center(
        child: Icon(Icons.mic, size: 48, color: theme.primaryColor.withOpacity(0.5)),
      ),
    );
  }
}

class _ScrollableSection extends StatefulWidget {
  final String title;
  final Widget Function(ScrollController) builder;
  const _ScrollableSection({required this.title, required this.builder});

  @override
  State<_ScrollableSection> createState() => _ScrollableSectionState();
}

class _ScrollableSectionState extends State<_ScrollableSection> {
  final ScrollController _controller = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    setState(() {
      _showLeft = _controller.offset > 10;
      _showRight = _controller.offset < _controller.position.maxScrollExtent - 10;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _showLeft ? () {
                      _controller.animateTo(
                        (_controller.offset - 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showLeft ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _showRight ? () {
                      _controller.animateTo(
                        (_controller.offset + 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showRight ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ),
        widget.builder(_controller),
      ],
    );
  }
}
