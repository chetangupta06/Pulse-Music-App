import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models/track.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    final currentIndex = ref.watch(queueProvider.notifier).currentIndex;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("UP NEXT", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text("${queue.length} Tracks", style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: queue.isEmpty 
              ? const Center(child: Text("Queue is empty"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    final isPlaying = index == currentIndex;
                    
                    return ListTile(
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(track.effectiveThumbnailUrl, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          if (isPlaying)
                            Container(
                               width: 44, height: 44,
                               decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                               child: Icon(Icons.play_arrow, color: theme.primaryColor),
                            ),
                        ],
                      ),
                      title: Text(
                        track.title, 
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                          color: isPlaying ? theme.primaryColor : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(track.artist, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        onPressed: () {
                           ref.read(queueProvider.notifier).removeAt(index);
                        },
                      ),
                      onTap: () {
                         ref.read(queueProvider.notifier).jumpTo(index);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

void showQueueSheet(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Queue",
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(-5, 0),
                )
              ],
            ),
            child: const QueueSheet(),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0))
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
