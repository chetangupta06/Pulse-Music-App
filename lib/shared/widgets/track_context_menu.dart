import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/track.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import 'playlist_picker_dialog.dart';

class TrackContextMenu extends ConsumerWidget {
  final Track track;
  final Widget child;
  
  const TrackContextMenu({super.key, required this.track, required this.child});

  void _showMenu(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    
    // Parse artists by splitting comma
    final artistNames = track.artist.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.black12,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: track.effectiveThumbnailUrl.isNotEmpty
                              ? Image.network(
                                  track.effectiveThumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => const Icon(Icons.music_note, color: Colors.grey),
                                )
                              : const Icon(Icons.music_note, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(track.title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(track.artist, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.dividerColor.withOpacity(0.5)),
                  
                  // Actions
                  _buildMenuItem(context, Icons.playlist_add_rounded, "Add to Playlist", () {
                    Navigator.pop(context);
                    showPlaylistPicker(context, ref, track);
                  }),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final favs = ref.watch(favoritesStreamProvider).value ?? [];
                      final isFav = favs.any((f) => f.youtubeId == track.youtubeId);
                      return _buildMenuItem(
                        context, 
                        isFav ? Icons.favorite : Icons.favorite_border, 
                        isFav ? "Remove from Liked Songs" : "Save to Liked Songs", 
                        () {
                          ref.read(isarDbProvider).toggleFavorite(track);
                          Navigator.pop(context);
                        },
                        iconColor: isFav ? theme.primaryColor : null,
                      );
                    }
                  ),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final downloads = ref.watch(downloadsStreamProvider).value ?? [];
                      final isDownloaded = track.isDownloaded || downloads.any((d) => d.youtubeId == track.youtubeId);
                      if (isDownloaded) return const SizedBox.shrink();
                      
                      return _buildMenuItem(context, Icons.download_rounded, "Download Track", () {
                        ref.read(downloadServiceProvider).startDownload(track);
                        Navigator.pop(context);
                      });
                    }
                  ),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final downloads = ref.watch(downloadsStreamProvider).value ?? [];
                      final isDownloaded = downloads.any((d) => d.youtubeId == track.youtubeId);
                      if (!isDownloaded) return const SizedBox.shrink();
                      
                      return _buildMenuItem(
                        context, 
                        Icons.delete_forever_rounded, 
                        "Delete from Device", 
                        () async {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (context) => AlertDialog(
                                title: const Text("Delete Download?"),
                                content: const Text("This track will be removed from your offline storage."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE")),
                                ],
                             )
                           );
                           if (confirm == true) {
                             await ref.read(isarDbProvider).deleteTrackDownload(track.youtubeId);
                             Navigator.pop(context);
                           }
                        },
                        iconColor: Colors.redAccent,
                      );
                    }
                  ),
                  
                  _buildMenuItem(context, Icons.queue_music_rounded, "Play Next", () {
                    ref.read(queueProvider.notifier).insertNext(track);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Will play next: ${track.title}')));
                  }),
                  
                  if (artistNames.isNotEmpty) ...[
                     Divider(color: theme.dividerColor.withOpacity(0.5)),
                     Padding(
                       padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                       child: Text("EXPLORE ARTISTS", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                     ),
                      for (final artist in artistNames) ...[
                        _buildMenuItem(context, Icons.person_search_rounded, "More from $artist", () {
                            Navigator.pop(context);
                            ref.read(navIndexProvider.notifier).setIndex(2); // Go to search
                            ref.read(searchQueryProvider.notifier).setQuery(artist);
                        }),
                        _buildMenuItem(context, Icons.star_border_rounded, "Add $artist to Top Artists", () {
                            ref.read(settingsProvider.notifier).addCustomArtist(artist);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pinned $artist to Top Artists!')));
                        }),
                      ]
                  ]
                ],
              ),
            ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? iconColor}) {
    final theme = Theme.of(context);
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: onTap,
            splashColor: theme.primaryColor.withOpacity(0.1),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent, // Let Container handle it
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: isHovered ? theme.colorScheme.onSurface.withOpacity(0.06) : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.7)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label, 
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: () => _showMenu(context, ref),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1) : Colors.transparent,
              ),
              child: child,
            ),
          ),
        );
      }
    );
  }
}
