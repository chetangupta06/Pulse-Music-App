import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/track.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_theme.dart';

class PlaylistPickerDialog extends ConsumerStatefulWidget {
  final Track track;
  const PlaylistPickerDialog({super.key, required this.track});

  @override
  ConsumerState<PlaylistPickerDialog> createState() => _PlaylistPickerDialogState();
}

class _PlaylistPickerDialogState extends ConsumerState<PlaylistPickerDialog> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _createNewPlaylist() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter playlist name",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _nameController.text),
            child: const Text("CREATE"),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(isarDbProvider).createPlaylist(name);
      _nameController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(isarDbProvider);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Save to Playlist", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _createNewPlaylist,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("NEW", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder(
              stream: db.watchSavedPlaylists(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final playlists = snapshot.data!.where((p) => p.type == 'user').toList();
                
                if (playlists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.playlist_add, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text("You haven't created any playlists yet.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _createNewPlaylist,
                          child: const Text("CREATE FIRST PLAYLIST"),
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final p = playlists[index];
                      return ListTile(
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.playlist_play, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                        ),
                        title: Text(p.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                        subtitle: Text("${p.tracks?.length ?? 0} tracks", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                        onTap: () async {
                           await db.addTrackToPlaylist(p.id, widget.track);
                           if (mounted) Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to ${p.title}")));
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

void showPlaylistPicker(BuildContext context, WidgetRef ref, Track track) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: PlaylistPickerDialog(track: track),
    ),
  );
}
