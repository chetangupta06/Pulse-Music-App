import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_playlist.dart';
import '../../core/models/track.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../core/providers.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/now_playing_wave.dart';

class PlaylistScreen extends ConsumerWidget {
  final AppPlaylist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final min = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve tracks from service dynamically
    final service = playlist.type == 'youtube' 
        ? ref.watch(ytdlpServiceProvider) 
        : ref.watch(musicServiceProvider);
    final tracksFuture = service.getPlaylistTracks(playlist.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder(
        future: tracksFuture,
        builder: (context, snap) {
          final tracks = snap.data ?? [];
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final isSaved = ref.watch(isarDbProvider).isPlaylistSaved(playlist.id);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 28,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.1), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10))
                          ]
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            playlist.effectiveThumbnailUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 600, cacheHeight: 600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                            Text(
                              playlist.title,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Curated Playlist • ${tracks.length} ${playlist.id.startsWith('MPSP') ? 'Episodes' : 'Songs'}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Row(
                              children: [
                                // Play Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 0,
                                  ),
                                  onPressed: tracks.isEmpty ? null : () {
                                    ref.read(queueProvider.notifier).playAll(tracks);
                                  },
                                  child: const Text("Play", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                const SizedBox(width: 16),
                                // Heart Button
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                                     color: isSaved ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    iconSize: 26,
                                    padding: const EdgeInsets.all(12),
                                    onPressed: isLoading ? null : () {
                                       final fullPlaylist = AppPlaylist()..id = playlist.id..title = playlist.title..type = playlist.type..thumbnailUrl = playlist.thumbnailUrl..tracks = tracks;
                                       if (isSaved) {
                                          ref.read(isarDbProvider).removePlaylist(playlist.id);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from Library')));
                                       } else {
                                          ref.read(isarDbProvider).savePlaylist(fullPlaylist);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "${playlist.title}" to Library'), backgroundColor: Theme.of(context).primaryColor));
                                       }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // More Menu Button
                                PopupMenuButton<String>(
                                  tooltip: "More options",
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  offset: const Offset(0, 50),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                    ),
                                    child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 26),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'download',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.download, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('Download All'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'play_next',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.playlist_play, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('Play Next'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'queue',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.queue_music, size: 20),
                                          const SizedBox(width: 12),
                                          const Text('Add to Queue'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (tracks.isEmpty) return;
                                    if (val == 'download') {
                                       for (var t in tracks) {
                                         ref.read(downloadServiceProvider).startDownload(t);
                                       }
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Downloading queue sequentially...'), backgroundColor: Theme.of(context).primaryColor));
                                    } else if (val == 'play_next') {
                                       ref.read(queueProvider.notifier).insertNext(tracks.first); 
                                    } else if (val == 'queue') {
                                       for (var t in tracks) {
                                         ref.read(queueProvider.notifier).enqueue(t);
                                       }
                                    }
                                  },
                                ),
                              ], // closes Row (buttons) children
                            ), // closes Row (buttons)
                          ], // closes Column (Details) children
                        ), // closes Column (Details)
                      ), // closes Expanded (Details)
                    ], // closes Row (Thumbnail + Details) children
                  ), // closes Row (Thumbnail + Details)
                ], // closes Column (Back button + Row) children
              ), // closes Column (Back button + Row)
            ), // closes SliverToBoxAdapter
          ), // closes SliverPadding
              
              if (isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SkeletonListRow(),
                      ),
                      childCount: 10,
                    ),
                  ),
                )
              else if (tracks.isEmpty)
                SliverFillRemaining(child: Center(child: Text("Empty playlist", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)))))
              else ...[
                // Track List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      "Trending Songs",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                // Tabular Track List Container
                SliverPadding(
                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Column(
                        children: List.generate(tracks.length, (index) {
                          return _buildTrackRow(context, ref, tracks[index], index, tracks);
                        }),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          );
        }
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, WidgetRef ref, Track t, int index, List<Track> allTracks) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return StatefulBuilder(
      builder: (context, setState) {
        bool hovering = false;
        return MouseRegion(
          onEnter: (_) => setState(() => hovering = true),
          onExit: (_) => setState(() => hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
               ref.read(queueProvider.notifier).playAll(allTracks, startIndex: index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: hovering ? onSurface.withOpacity(0.03) : Colors.transparent,
                border: index < allTracks.length - 1 
                    ? Border(bottom: BorderSide(color: onSurface.withOpacity(0.05)))
                    : null,
              ),
              child: Row(
                children: [
                  // Index
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: hovering 
                        ? Icon(Icons.play_arrow, color: onSurface.withOpacity(0.8), size: 20)
                        : Text("${index + 1}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Thumbnail + Title
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 40, height: 40,
                            child: Stack(
                              children: [
                                Image.network(
                                  t.effectiveThumbnailUrl,
                                  width: 40, height: 40,
                                  fit: BoxFit.cover,
                                  cacheWidth: 150, cacheHeight: 150,
                                ),
                                // Now playing waveform overlay
                                Consumer(
                                  builder: (context, ref, child) {
                                    final currentTrack = ref.watch(currentTrackProvider);
                                    final isPlayingAsync = ref.watch(playbackStateProvider);
                                    final isThisTrack = currentTrack?.youtubeId == t.youtubeId;
                                    final isPlaying = isPlayingAsync.valueOrNull ?? false;
                                    
                                    if (isThisTrack) {
                                      return Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Center(
                                            child: NowPlayingWave(
                                              size: 18,
                                              color: Theme.of(context).primaryColor,
                                              isPlaying: isPlaying,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Artists
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.artist,
                      style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Album (Using Title if missing)
                  Expanded(
                    flex: 2,
                    child: Text(
                      t.title,
                      style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Actions (Heart)
                  Consumer(
                    builder: (context, ref, child) {
                      final favs = ref.watch(favoritesStreamProvider).value ?? [];
                      final isFav = favs.any((f) => f.youtubeId == t.youtubeId);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                        color: isFav ? Colors.redAccent : onSurface.withOpacity(0.4),
                        iconSize: 20,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onPressed: () => ref.read(isarDbProvider).toggleFavorite(t),
                      );
                    }
                  ),
                  const SizedBox(width: 8),
                  // More or Duration
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatDuration(t.durationMs),
                          style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        TrackContextMenu(
                          track: t,
                          child: Icon(Icons.more_horiz, color: onSurface.withOpacity(hovering ? 0.9 : 0.4), size: 22),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
