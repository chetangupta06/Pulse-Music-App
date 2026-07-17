import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../core/providers.dart';
import 'lyrics_panel.dart';
import 'queue_sheet.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/hover_container.dart';
import 'now_playing_screen.dart';

class BottomPlayer extends ConsumerWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(playbackStateProvider).value ?? false;
    final buffering = ref.watch(bufferingStateProvider).value ?? false;
    final position = ref.watch(positionStateProvider).value ?? Duration.zero;
    final duration = ref.watch(durationStateProvider).value ?? Duration.zero;
    final volume = ref.watch(volumeStateProvider).value ?? 100.0;

    // Show SnackBar when a stream error occurs
    ref.listen<String?>(saavnErrorProvider, (_, error) {
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(error, style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E2E),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 108),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    
    String formatDuration(Duration d) {
      final s = d.inSeconds % 60;
      final m = d.inMinutes;
      return m.toString() + ':' + s.toString().padLeft(2, '0');
    }

    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isHovered = false;
                return MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onPanUpdate: (drag) {
                      final width = MediaQuery.of(context).size.width;
                      final ratio = (drag.globalPosition.dx / width).clamp(0.0, 1.0);
                      ref.read(audioHandlerProvider).seek(duration * ratio);
                    },
                    onTapDown: (tap) {
                      final width = MediaQuery.of(context).size.width;
                      final ratio = (tap.globalPosition.dx / width).clamp(0.0, 1.0);
                      ref.read(audioHandlerProvider).seek(duration * ratio);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isHovered ? 8 : 4,
                      color: Colors.transparent,
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(
                        value: (duration.inMilliseconds > 0) ? position.inMilliseconds / duration.inMilliseconds : 0,
                        backgroundColor: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        minHeight: isHovered ? 4 : 2,
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: Track Info
                Expanded(
                  flex: 3,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      bool isHovered = false;
                      return MouseRegion(
                        onEnter: (_) => setState(() => isHovered = true),
                        onExit: (_) => setState(() => isHovered = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isHovered && track != null ? Colors.white.withOpacity(0.04) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: track == null ? null : () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(0.0, 1.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeOutQuart;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    return SlideTransition(position: animation.drive(tween), child: child);
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 56, height: 56,
                                      color: Colors.black26,
                                      child: track != null
                                          ? Image.network(
                                              track.effectiveThumbnailUrl,
                                              fit: BoxFit.cover,
                                              cacheWidth: 120, // Optimization
                                              cacheHeight: 120,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.grey),
                                            )
                                          : const Icon(Icons.music_note, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          track?.title ?? "No Track Playing",
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: isHovered ? Theme.of(context).primaryColor : null),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          track != null ? track.artist : "--",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),

                // CENTER: Controls
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shuffle Button (Moved to far left of controls)
                      IconButton(
                        icon: Icon(
                          ref.watch(queueProvider.notifier).isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                        ),
                        onPressed: () => ref.read(queueProvider.notifier).toggleShuffle(),
                        color: ref.watch(queueProvider.notifier).isShuffle 
                           ? Theme.of(context).primaryColor 
                           : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        iconSize: 22,
                        tooltip: "Shuffle",
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded), 
                        onPressed: () => ref.read(queueProvider.notifier).playPrevious(), 
                        iconSize: 32, 
                        color: Theme.of(context).colorScheme.onSurface
                      ),
                      const SizedBox(width: 8),
                      // Play/Pause Pill
                      StatefulBuilder(
                        builder: (context, setState) {
                          bool isBtnHovered = false;
                          return MouseRegion(
                            onEnter: (_) => setState(() => isBtnHovered = true),
                            onExit: (_) => setState(() => isBtnHovered = false),
                            child: AnimatedScale(
                              scale: isBtnHovered ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: InkWell(
                                onTap: () {
                                  final handler = ref.read(audioHandlerProvider);
                                  if (isPlaying) handler.pause(); else handler.play();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(isBtnHovered ? 0.9 : 1.0),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      if (isBtnHovered) BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: buffering
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(isPlaying ? "Pause" : "Play", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded), 
                        onPressed: () => ref.read(queueProvider.notifier).playNext(), 
                        iconSize: 32, 
                        color: Theme.of(context).colorScheme.onSurface
                      ),
                      const SizedBox(width: 8),
                      // Repeat Button
                      IconButton(
                        icon: Icon(
                          ref.watch(queueProvider.notifier).repeatMode == 'one' 
                            ? Icons.repeat_one_rounded 
                            : (ref.watch(queueProvider.notifier).repeatMode == 'all' ? Icons.repeat_on_rounded : Icons.repeat_rounded),
                        ),
                        onPressed: () => ref.read(queueProvider.notifier).nextRepeatMode(),
                        color: ref.watch(queueProvider.notifier).repeatMode != 'none' 
                           ? Theme.of(context).primaryColor 
                           : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        iconSize: 22,
                        tooltip: "Repeat Mode",
                      ),
                    ],
                  ),
                ),
                
                // RIGHT: Actions & Time
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      Text(
                        "${formatDuration(position)} / ${formatDuration(duration)}", 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)
                      ),
                      const SizedBox(width: 16),
                      // Lyrics Icon
                      if (track != null)
                        IconButton(
                          icon: const Icon(Icons.lyrics_outlined), 
                          onPressed: () => showLyrics(context, track), 
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          iconSize: 22,
                          tooltip: "Lyrics",
                        ),
                      // Favorites Icon
                      ref.watch(favoritesStreamProvider).when(
                        data: (favs) {
                          final isFav = track != null && favs.any((f) => f.youtubeId == track.youtubeId);
                          return IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border), 
                            color: isFav ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            iconSize: 22,
                            onPressed: track != null ? () {
                               ref.read(isarDbProvider).toggleFavorite(track);
                            } : null,
                          );
                        },
                        loading: () => const IconButton(icon: Icon(Icons.favorite_border), onPressed: null),
                        error: (_, __) => const IconButton(icon: Icon(Icons.favorite_border), onPressed: null),
                      ),
                      // Download Icon Logic
                      Builder(
                        builder: (context) {
                           final progressMap = ref.watch(downloadProgressProvider);
                           final progress = track != null ? progressMap[track.youtubeId] : null;
                           final isAlreadyDownloaded = track?.isDownloaded == true;
                           
                           if (isAlreadyDownloaded || (progress != null && progress >= 2.0)) {
                             return const IconButton(
                               icon: Icon(Icons.download_done_rounded, color: Color(0xFF2BC5B4), size: 22),
                               tooltip: "Downloaded",
                               onPressed: null,
                             );
                           }
                           
                           if (progress == -1.0) {
                             return IconButton(
                               icon: const Icon(Icons.error_outline, color: Colors.orange, size: 22),
                               tooltip: "Failed to download",
                               onPressed: track != null ? () => ref.read(downloadServiceProvider).startDownload(track) : null,
                             );
                           }
                           
                           if (progress != null && progress > 0.0 && progress < 1.0) {
                             return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 12),
                               child: SizedBox(
                                 width: 18, height: 18,
                                 child: CircularProgressIndicator(
                                   value: progress,
                                   strokeWidth: 2,
                                   color: Theme.of(context).primaryColor,
                                 ),
                               ),
                             );
                           }
                           
                           return IconButton(
                             icon: const Icon(Icons.download_rounded, size: 22),
                             tooltip: "Download Track",
                             onPressed: track != null ? () => ref.read(downloadServiceProvider).startDownload(track) : null,
                             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                           );
                        }
                      ),
                      // Three dots context menu trigger
                      if (track != null)
                        TrackContextMenu(
                          track: track,
                          child: HoverContainer(
                            padding: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(20),
                            child: Icon(Icons.more_horiz_rounded, size: 24, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        )
                      else
                        IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 24), onPressed: null),
                      const SizedBox(width: 8),
                      // Volume icon with slider popup
                      _VolumeControl(volume: volume, ref: ref),
                      const SizedBox(width: 8),
                      // Mini Player Toggle
                      IconButton(
                        icon: const Icon(Icons.picture_in_picture_alt_rounded, size: 20),
                        tooltip: "Mini Player",
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        onPressed: () async {
                          ref.read(isMiniPlayerProvider.notifier).state = true;
                        },
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final double volume;
  final WidgetRef ref;
  const _VolumeControl({required this.volume, required this.ref});

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  double _lastVolume = 100.0;
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    final vol = widget.volume;
    return MouseRegion(
      onEnter: (_) {
        _hideTimer?.cancel();
        _showSlider();
      },
      onExit: (_) {
        _hideTimer = Timer(const Duration(milliseconds: 300), () {
          _hideSlider();
        });
      },
      child: GestureDetector(
        onTap: () {
          final handler = widget.ref.read(audioHandlerProvider);
          if (vol > 0) {
            _lastVolume = vol;
            handler.player.setVolume(0);
          } else {
            handler.player.setVolume(_lastVolume > 0 ? _lastVolume : 100);
          }
        },
        child: HoverContainer(
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            vol == 0 ? Icons.volume_off_rounded : (vol < 50 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showSlider() {
    _overlayEntry?.remove();
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final theme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 12,
        bottom: MediaQuery.of(context).size.height - offset.dy + 8,
        child: MouseRegion(
          onEnter: (_) {
            _hideTimer?.cancel();
          },
          onExit: (_) {
            _hideTimer = Timer(const Duration(milliseconds: 300), () {
               _hideSlider();
            });
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 60,
              height: 160,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setSliderState) {
                  return StreamBuilder<double>(
                    stream: widget.ref.read(audioHandlerProvider).player.stream.volume,
                    builder: (context, snap) {
                      final vol = snap.data ?? 100.0;
                      return RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            activeTrackColor: theme.primaryColor,
                            inactiveTrackColor: theme.dividerColor,
                            thumbColor: theme.primaryColor,
                            overlayColor: theme.primaryColor.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: vol.clamp(0, 100),
                            min: 0,
                            max: 100,
                            onChanged: (v) {
                              widget.ref.read(audioHandlerProvider).player.setVolume(v);
                              setSliderState(() {});
                            },
                          ),
                        ),
                      );
                    }
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSlider() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
