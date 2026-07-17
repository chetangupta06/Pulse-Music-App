import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/models/track.dart';
import 'package:pulse/core/providers.dart';
import 'package:pulse/shared/theme/app_theme.dart';
import 'package:pulse/shared/widgets/track_details_sheet.dart';
import 'package:pulse/shared/widgets/track_context_menu.dart';
import 'package:pulse/shared/widgets/hover_container.dart';
import 'package:pulse/shared/widgets/now_playing_wave.dart';

class TrackCard extends ConsumerStatefulWidget {
  final Track track;
  final double? width;
  final double rightMargin;
  const TrackCard({super.key, required this.track, this.width = 120, this.rightMargin = 20});

  @override
  ConsumerState<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends ConsumerState<TrackCard> {
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    // Warm up the stream URL in the background to ensure instant playback upon click
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(queueProvider.notifier).preWarmLink(widget.track);
    });
  }

  void _showDetails() {
    showTrackDetails(context, ref, widget.track);
  }

  void _playTrack() async {
    ref.read(queueProvider.notifier).playAll([widget.track]);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _playTrack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          margin: EdgeInsets.only(right: widget.rightMargin),
          transform: _isHovering ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                   Container(
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8),
                       boxShadow: [
                         BoxShadow(
                           color: Theme.of(context).primaryColor.withOpacity(0.05),
                           blurRadius: 15,
                           spreadRadius: 2,
                         )
                       ],
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(8),
                       child: AspectRatio(
                         aspectRatio: 1.0,
                         child: Image.network(
                           widget.track.effectiveThumbnailUrl,
                           fit: BoxFit.cover,
                           cacheWidth: 300,
                           cacheHeight: 300,
                           errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, size: 48, color: Colors.white24),
                         ),
                       ),
                     ),
                   ),
                   
                   // Hover Overlay
                   if (_isHovering)
                     Positioned.fill(
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(8),
                           color: Colors.black.withOpacity(0.5),
                         ),
                         child: Stack(
                           children: [
                             // Center Play Button
                             Center(
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.black.withOpacity(0.6),
                                   shape: BoxShape.circle,
                                 ),
                                 child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                               ),
                             ),
                             // Bottom Left Heart
                             Positioned(
                               bottom: 8, left: 8,
                               child: Consumer(
                                 builder: (context, ref, child) {
                                   final favorites = ref.watch(favoritesStreamProvider).value ?? [];
                                   final isFav = favorites.any((t) => t.youtubeId == widget.track.youtubeId);
                                   return GestureDetector(
                                     onTap: () {
                                        ref.read(isarDbProvider).toggleFavorite(widget.track);
                                     },
                                     child: Icon(
                                       isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                                       color: isFav ? Colors.redAccent : Colors.white, 
                                       size: 16
                                     ),
                                   );
                                 },
                               ),
                             ),
                             // Bottom Right Context Menu
                             Positioned(
                               bottom: 8, right: 8,
                               child: TrackContextMenu(
                                 track: widget.track,
                                 child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 16),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),

                    // Now Playing waveform indicator
                    Consumer(
                      builder: (context, ref, child) {
                        final currentTrack = ref.watch(currentTrackProvider);
                        final isPlayingAsync = ref.watch(playbackStateProvider);
                        final isThisTrack = currentTrack?.youtubeId == widget.track.youtubeId;
                        final isPlaying = isPlayingAsync.valueOrNull ?? false;
                        
                        if (isThisTrack) {
                          return Positioned(
                            bottom: 6, right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: NowPlayingWave(
                                size: 16,
                                color: Theme.of(context).primaryColor,
                                isPlaying: isPlaying,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Download status (always visible if downloading/downloaded)
                    Consumer(
                      builder: (context, ref, child) {
                        final progress = ref.watch(downloadProgressProvider)[widget.track.youtubeId] ?? 0.0;
                        final downloads = ref.watch(downloadsStreamProvider).value ?? [];
                        final isDownloadedByDb = downloads.any((d) => d.youtubeId == widget.track.youtubeId);
                        final isDownloaded = widget.track.isDownloaded || isDownloadedByDb || progress == 2.0;

                        if (progress > 0 && progress < 1.0) {
                          return Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                              child: const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent)),
                            ),
                          );
                        }
                        
                        if (isDownloaded) {
                          return Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                            ),
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.track.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 0.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.track.artist,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

