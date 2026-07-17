import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../shared/widgets/hover_container.dart';
import '../../shared/widgets/track_context_menu.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFavorites = ref.watch(favoritesStreamProvider);
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Saved Tracks",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Tracks you've saved to your library.",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: asyncFavorites.when(
              data: (tracks) {
                if (tracks.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text("No favorites yet.", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tracks.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return HoverContainer(
                          onTap: () => ref.read(queueProvider.notifier).playAll(tracks, startIndex: index),
                          hoverDecoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: index == 0 
                                ? const BorderRadius.vertical(top: Radius.circular(16)) 
                                : (index == tracks.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: track.thumbnailUrl.isNotEmpty 
                                 ? Image.network(track.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover)
                                 : Container(width: 48, height: 48, color: theme.colorScheme.surfaceContainerHighest, child: const Icon(Icons.music_note)),
                            ),
                            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                            trailing: TrackContextMenu(track: track, child: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: theme.primaryColor))),
              error: (e, st) => SliverFillRemaining(child: Center(child: Text("Error: $e", style: TextStyle(color: theme.colorScheme.error)))),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
