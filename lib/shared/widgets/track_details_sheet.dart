import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/track.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../features/player/lyrics_panel.dart';
import '../../shared/widgets/playlist_picker_dialog.dart';

void showTrackDetails(BuildContext context, WidgetRef ref, Track track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _TrackDetailsSheet(track: track),
  );
}

class _TrackDetailsSheet extends ConsumerWidget {
  final Track track;
  const _TrackDetailsSheet({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Art, Title, Artist, Top Right Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(track.effectiveThumbnailUrl, width: 80, height: 80, fit: BoxFit.cover, cacheWidth: 160, cacheHeight: 160),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, 
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(track.artist, 
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    onPressed: () => ref.read(isarDbProvider).toggleFavorite(track),
                  ),
                  IconButton(
                    icon: Icon(Icons.download_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    onPressed: () => ref.read(downloadServiceProvider).startDownload(track),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick Action Bar: Play next, Add to playlist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickButton(context, Icons.playlist_play, "Play next", () {
                ref.read(queueProvider.notifier).insertNext(track);
                Navigator.pop(context);
              }),
              _buildQuickButton(context, Icons.playlist_add, "Add to playlist", () {
                Navigator.pop(context);
                showPlaylistPicker(context, ref, track);
              }),
            ],
          ),
          const SizedBox(height: 32),
          
          // Functional Actions List
          _buildActionRow(context, Icons.playlist_play, "Play next", () {
            ref.read(queueProvider.notifier).insertNext(track);
            Navigator.pop(context);
          }),
          _buildActionRow(context, Icons.playlist_add, "Add to playlist", () {
             Navigator.pop(context);
             showPlaylistPicker(context, ref, track);
          }),
          _buildActionRow(context, Icons.queue_music_outlined, "Enqueue this song", () {
            ref.read(queueProvider.notifier).enqueue(track);
            Navigator.pop(context);
          }),
          _buildActionRow(context, Icons.open_in_new_outlined, "Open in", () {}, trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.play_circle_outline, color: Colors.white70, size: 24),
               const SizedBox(width: 16),
               Icon(Icons.play_circle_filled, color: Colors.white70, size: 24),
            ],
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100, height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, IconData icon, String label, VoidCallback onTap, {Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 24),
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500))),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
