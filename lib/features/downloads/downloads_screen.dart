import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../shared/widgets/hover_container.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../shared/widgets/now_playing_wave.dart';
import '../../core/models/track.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleTrack(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected(List<Track> allTracks) async {
    final toDelete = allTracks.where((t) => _selectedIds.contains(t.youtubeId)).toList();
    if (toDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${toDelete.length} tracks?"),
        content: const Text("This will remove the downloaded files from your device."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(isarDbProvider);
      for (var track in toDelete) {
        await db.deleteTrackDownload(track.youtubeId);
      }
      _toggleSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDownloads = ref.watch(downloadsStreamProvider);
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: asyncDownloads.when(
        data: (tracks) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelectionMode ? "${_selectedIds.length} Selected" : "Offline Audio",
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Offline music available on this device.",
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontSize: 14),
                        ),
                      ],
                    ),
                    if (tracks.isNotEmpty) ...[
                      Row(
                        children: [
                          if (_isSelectionMode) ...[
                            IconButton(
                              icon: const Icon(Icons.select_all_rounded),
                              onPressed: () => setState(() => _selectedIds.addAll(tracks.map((t) => t.youtubeId))),
                              tooltip: "Select All",
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                              onPressed: () => _deleteSelected(tracks),
                              tooltip: "Delete Selected",
                            ),
                          ],
                          TextButton(
                            onPressed: _toggleSelectionMode,
                            child: Text(_isSelectionMode ? "CANCEL" : "SELECT", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: tracks.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_done, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text("No downloaded tracks yet.", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
                    ),
                  )
                : SliverToBoxAdapter(
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
                          final t = tracks[index];
                          final isSelected = _selectedIds.contains(t.youtubeId);
                          
                          return HoverContainer(
                            onTap: _isSelectionMode 
                                ? () => _toggleTrack(t.youtubeId) 
                                : () => ref.read(queueProvider.notifier).playAll(tracks, startIndex: index),
                            hoverDecoration: BoxDecoration(
                              color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.colorScheme.onSurface.withOpacity(0.05),
                              borderRadius: index == 0 
                                  ? const BorderRadius.vertical(top: Radius.circular(16)) 
                                  : (index == tracks.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
                            ),
                            child: Container(
                              color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: t.thumbnailUrl.isNotEmpty 
                                         ? Image.network(
                                             t.thumbnailUrl, 
                                             width: 48, 
                                             height: 48, 
                                             fit: BoxFit.cover,
                                             errorBuilder: (_, __, ___) => Container(
                                               width: 48, 
                                               height: 48, 
                                               color: theme.colorScheme.surfaceContainerHighest, 
                                               child: const Icon(Icons.music_note)
                                             ),
                                           )
                                         : Container(width: 48, height: 48, color: theme.colorScheme.surfaceContainerHighest, child: const Icon(Icons.music_note)),
                                    ),
                                    if (_isSelectionMode && isSelected)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.check, color: Colors.white),
                                        ),
                                      ),
                                    // Now playing waveform overlay
                                    if (!_isSelectionMode)
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
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: NowPlayingWave(
                                                    size: 20,
                                                    color: theme.primaryColor,
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
                                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                trailing: _isSelectionMode ? null : TrackContextMenu(track: t, child: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator(color: theme.primaryColor)),
        error: (e, st) => Center(child: Text("Error: $e", style: TextStyle(color: theme.colorScheme.error))),
      ),
    );
  }
}
