import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_playlist.dart';
import '../../core/providers.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/now_playing_wave.dart' as pulse_wave;
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/scrollable_track_row.dart';

class UserPlaylistsScreen extends ConsumerStatefulWidget {
  const UserPlaylistsScreen({super.key});

  @override
  ConsumerState<UserPlaylistsScreen> createState() => _UserPlaylistsScreenState();
}

class _UserPlaylistsScreenState extends ConsumerState<UserPlaylistsScreen> {
  AppPlaylist? _selectedPlaylist;

  @override
  Widget build(BuildContext context) {
    final db = ref.read(isarDbProvider);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _selectedPlaylist == null 
        ? _buildPlaylistList(db) 
        : _buildPlaylistDetail(_selectedPlaylist!),
    );
  }

  Widget _buildPlaylistList(dynamic db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Collections", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Theme.of(context).colorScheme.onSurface)),
              ElevatedButton.icon(
                onPressed: () => _createNewPlaylist(db),
                icon: const Icon(Icons.add),
                label: const Text("CREATE"),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppPlaylist>>(
            stream: db.watchSavedPlaylists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final List<AppPlaylist> allPlaylists = snapshot.data!;

              if (allPlaylists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                      const SizedBox(height: 24),
                      Text("No playlists yet.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => _createNewPlaylist(db), child: const Text("Create your first playlist")),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.7,
                ),
                itemCount: allPlaylists.length,
                itemBuilder: (context, index) {
                  final p = allPlaylists[index];
                  final isUser = p.type == 'user';
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlaylist = p),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  image: (!isUser && p.thumbnailUrl.isNotEmpty) 
                                    ? DecorationImage(image: NetworkImage(p.thumbnailUrl), fit: BoxFit.cover)
                                    : null,
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                                ),
                                child: isUser 
                                  ? const Icon(Icons.playlist_play, size: 60, color: Colors.white24)
                                  : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(p.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(isUser ? "${p.tracks?.length ?? 0} tracks" : "External Playlist", style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: PopupMenuButton<String>(
                             icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
                             onSelected: (value) async {
                                if (value == 'rename') {
                                  _renamePlaylist(p);
                                } else if (value == 'delete') {
                                   final confirm = await showDialog<bool>(
                                     context: context,
                                     builder: (context) => AlertDialog(
                                        title: const Text("Delete Playlist?"),
                                        content: const Text("This action cannot be undone."),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE")),
                                        ],
                                     )
                                   );
                                   if (confirm == true) {
                                      await ref.read(isarDbProvider).removePlaylist(p.id);
                                   }
                                }
                             },
                             itemBuilder: (context) => [
                               const PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.edit), title: Text("Rename"))),
                               const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text("Delete", style: TextStyle(color: Colors.red)))),
                             ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistDetail(AppPlaylist playlist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(onPressed: () => setState(() => _selectedPlaylist = null), icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: Text(playlist.title, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48))),
                        if (playlist.type == 'user') ...[
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(Icons.edit_note, size: 32, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            onPressed: () => _renamePlaylist(playlist),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_circle_fill, size: 64, color: Theme.of(context).primaryColor),
                        onPressed: () {
                           if (playlist.tracks != null && playlist.tracks!.isNotEmpty) {
                             ref.read(queueProvider.notifier).playAll(playlist.tracks!);
                           }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 28),
                        onPressed: () async {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (context) => AlertDialog(
                               title: const Text("Delete Playlist?"),
                               content: const Text("This action cannot be undone."),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
                                 TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE")),
                               ],
                             )
                           );
                           if (confirm == true) {
                             await ref.read(isarDbProvider).removePlaylist(playlist.id);
                             setState(() => _selectedPlaylist = null);
                           }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: playlist.tracks == null || playlist.tracks!.isEmpty 
            ? Center(child: Text("Empty playlist", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                itemCount: playlist.tracks!.length,
                itemBuilder: (context, index) {
                   final t = playlist.tracks![index];
                   final onSurface = Theme.of(context).colorScheme.onSurface;
                   return ListTile(
                     leading: SizedBox(
                       width: 48, height: 48,
                       child: Stack(
                         children: [
                           ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(t.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover)),
                           Consumer(
                             builder: (context, ref, child) {
                               final currentTrack = ref.watch(currentTrackProvider);
                               final isPlayingAsync = ref.watch(playbackStateProvider);
                               final isThisTrack = currentTrack?.youtubeId == t.youtubeId;
                               final isPlaying = isPlayingAsync.valueOrNull ?? false;
                               
                               if (isThisTrack) {
                                 return Container(
                                   decoration: BoxDecoration(
                                     color: Colors.black.withOpacity(0.6),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: Center(
                                     child: pulse_wave.NowPlayingWave(isPlaying: isPlaying, color: Colors.white, size: 16),
                                   ),
                                 );
                               }
                               return const SizedBox();
                             },
                           ),
                         ],
                       ),
                     ),
                     title: Text(t.title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                     subtitle: Text(t.artist, style: TextStyle(color: onSurface.withOpacity(0.5))),
                     trailing: IconButton(
                       icon: Icon(Icons.remove_circle_outline, color: onSurface.withOpacity(0.2)),
                       onPressed: () async {
                          await ref.read(isarDbProvider).removeTrackFromPlaylist(playlist.id, t.youtubeId);
                          // Refresh manually as we are using a cached list object
                          final updated = (await ref.read(isarDbProvider).watchSavedPlaylists().first).firstWhere((x) => x.id == playlist.id);
                          setState(() => _selectedPlaylist = updated);
                       },
                     ),
                     onTap: () {
                        ref.read(queueProvider.notifier).playAll(playlist.tracks!, startIndex: index);
                     },
                   );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _renamePlaylist(AppPlaylist playlist) async {
    final controller = TextEditingController(text: playlist.title);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("RENAME")),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != playlist.title) {
      await ref.read(isarDbProvider).renamePlaylist(playlist.id, newName);
      // Refresh state
      final updated = (await ref.read(isarDbProvider).watchSavedPlaylists().first).firstWhere((x) => x.id == playlist.id);
      setState(() => _selectedPlaylist = updated);
    }
  }

  Future<void> _createNewPlaylist(dynamic db) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("CREATE")),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await db.createPlaylist(name);
    }
  }
}
