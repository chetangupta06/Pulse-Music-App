import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models/track.dart';
import '../../shared/widgets/hover_container.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_outlined, size: 80, color: Colors.white10),
              SizedBox(height: 16),
              Text("Select a song to start listening", 
                style: TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    final queue = ref.watch(queueProvider);
    final isPlaying = ref.watch(playbackStateProvider).value ?? false;
    final buffering = ref.watch(bufferingStateProvider).value ?? false;
    final position = ref.watch(positionStateProvider).value ?? Duration.zero;
    final duration = ref.watch(durationStateProvider).value ?? Duration.zero;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // LEFT SIDE: Main Art & Controls
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.network(
                  track.effectiveThumbnailUrl,
                  fit: BoxFit.cover,
                ),
                // Glassmorphism Blur
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.65),
                  ),
                ),
                // Overlay Gradient for extra legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      const Text("Now Playing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  // Large Artwork (Centered)
                  Expanded(
                    flex: 12,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 540),
                        child: Hero(
                          tag: 'player_art',
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 50,
                                    offset: const Offset(0, 25),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(track.effectiveThumbnailUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Info & Logic Controls
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        Text(
                          track.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 36),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          track.artist,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Progress Bar
                        _buildProgressBar(context, ref, position, duration),
                        const SizedBox(height: 32),
                        // Playback Buttons
                        _buildMainControls(context, ref, isPlaying, buffering),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // RIGHT SIDE: Queue List (Sidebar)
          Container(
            width: 380,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      const Text("Up Next", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text("${queue.length} Tracks", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, size: 20),
                        onPressed: () {
                           ref.read(navIndexProvider.notifier).setIndex(2);
                           Navigator.pop(context);
                        },
                        tooltip: "Search & Add Songs",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: queue.length,
                    onReorder: (oldIndex, newIndex) {
                      ref.read(queueProvider.notifier).reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = index == ref.watch(queueProvider.notifier).currentIndex;
                      return HoverContainer(
                        key: ValueKey('${item.id}_$index'),
                        hoverScale: 1.0,
                        onTap: () => ref.read(queueProvider.notifier).jumpTo(index),
                        hoverDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildSafeThumbnail(item.effectiveThumbnailUrl),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Theme.of(context).primaryColor : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(item.artist, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Icon(Icons.equalizer_rounded, size: 18, color: Theme.of(context).primaryColor)
                              else if (index > ref.watch(queueProvider.notifier).currentIndex)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () => ref.read(queueProvider.notifier).removeAt(index),
                                ),
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(Icons.drag_indicator_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, WidgetRef ref, Duration pos, Duration dur) {
    final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
    
    String format(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return "$m:${s.toString().padLeft(2, '0')}";
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.1),
            thumbColor: Theme.of(context).primaryColor,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) {
              ref.read(audioHandlerProvider).seek(dur * v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(format(pos), style: Theme.of(context).textTheme.bodySmall),
              Text(format(dur), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls(BuildContext context, WidgetRef ref, bool isPlaying, bool buffering) {
    final queueNotifier = ref.watch(queueProvider.notifier);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(queueNotifier.isShuffle ? Icons.shuffle_on : Icons.shuffle),
          onPressed: () => queueNotifier.toggleShuffle(),
          color: queueNotifier.isShuffle ? Theme.of(context).primaryColor : null,
          iconSize: 26,
        ),
        const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: () => queueNotifier.playPrevious(),
          iconSize: 56,
        ),
        const SizedBox(width: 48),
        HoverContainer(
          hoverScale: 1.1,
          onTap: () {
            final h = ref.read(audioHandlerProvider);
            if (isPlaying) h.pause(); else h.play();
          },
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Center(
              child: buffering 
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 56),
            ),
          ),
        ),
        const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: () => queueNotifier.playNext(),
          iconSize: 56,
        ),
        const SizedBox(width: 48),
        IconButton(
          icon: Icon(
            queueNotifier.repeatMode == 'one' ? Icons.repeat_one_on : 
            (queueNotifier.repeatMode == 'all' ? Icons.repeat_on : Icons.repeat)
          ),
          onPressed: () => queueNotifier.nextRepeatMode(),
          color: queueNotifier.repeatMode != 'none' ? Theme.of(context).primaryColor : null,
          iconSize: 26,
        ),
      ],
    );
  }

  Widget _buildSafeThumbnail(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 44, height: 44,
        color: Colors.white.withOpacity(0.05),
        child: Image.network(
          url?.isEmpty ?? true ? 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?q=80&w=100&auto=format&fit=crop' : url!,
          width: 44, height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, size: 20, color: Colors.white24),
        ),
      ),
    );
  }
}
