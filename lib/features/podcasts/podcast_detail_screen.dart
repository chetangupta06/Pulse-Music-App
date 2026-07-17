import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:podcast_search/podcast_search.dart';
import '../../core/api/podcast_service.dart';
import '../../core/models/track.dart' hide Track;
import '../../core/models/track.dart' as desi;
import '../../core/providers.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/hover_container.dart';

final podcastFeedProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, feedUrl) async {
  final service = ref.watch(podcastServiceProvider);
  return service.loadPodcast(feedUrl);
});

class PodcastDetailScreen extends ConsumerWidget {
  final String feedUrl;
  const PodcastDetailScreen({super.key, required this.feedUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(podcastFeedProvider(feedUrl));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          
          asyncData.when(
            data: (data) {
              final Podcast podcast = data['podcast'];
              final List<desi.Track> tracks = data['tracks'];
              
              return SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context, ref, podcast, tracks),
                  _buildEpisodesList(context, ref, tracks),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: SkeletonPlaylistHeader(),
              ),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(
                child: Text("Error parsing podcast feed: $e", style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Podcast podcast, List<desi.Track> tracks) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: theme.shadowColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
              ],
              image: DecorationImage(
                image: NetworkImage(podcast.image ?? 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?q=80&w=400&auto=format&fit=crop'),
                fit: BoxFit.cover,
              )
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PODCAST", style: theme.textTheme.labelMedium?.copyWith(color: theme.primaryColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  podcast.title ?? 'Unknown',
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                Text(
                  "By ${podcast.copyright ?? 'Unknown'}",
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                if (podcast.description != null)
                  Text(
                    desi.Track.decodeHtml(podcast.description!),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5), height: 1.5),
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                         if (tracks.isNotEmpty) {
                           ref.read(queueProvider.notifier).playAll(tracks);
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text("PLAY LATEST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList(BuildContext context, WidgetRef ref, List<desi.Track> tracks) {
    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: Text("No playable episodes found.")),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Episodes",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final t = tracks[index];
                return HoverContainer(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(t.effectiveThumbnailUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox(width: 48, height: 48, child: Icon(Icons.mic))),
                    ),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${(t.durationMs / 60000).ceil()} mins", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    trailing: TrackContextMenu(track: t, child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    onTap: () {
                      ref.read(queueProvider.notifier).playAll(tracks, startIndex: index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
