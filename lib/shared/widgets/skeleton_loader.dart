import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final Widget child;
  const SkeletonLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = theme.colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.04);
    final highlightColor = theme.colorScheme.onSurface.withOpacity(isDark ? 0.15 : 0.08);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key, 
    this.width = double.infinity, 
    this.height = double.infinity,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer will mask this with the baseColor
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Mimics a TrackCard in the Discover horizontally scrolling lists
class SkeletonTrackCard extends StatelessWidget {
  const SkeletonTrackCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: SkeletonBox(borderRadius: 16),
          ),
          const SizedBox(height: 12),
          const SkeletonBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 8),
          const SkeletonBox(width: 80, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

// Mimics a vertical list item in Search or Playlist screens
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const SkeletonBox(width: 48, height: 48, borderRadius: 8),
        title: const SkeletonBox(width: 200, height: 16, borderRadius: 4),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: SkeletonBox(width: 120, height: 12, borderRadius: 4),
        ),
        trailing: const SkeletonBox(width: 24, height: 24, borderRadius: 12),
      ),
    );
  }
}

// Mimics the header of a PlaylistScreen
class SkeletonPlaylistHeader extends StatelessWidget {
  const SkeletonPlaylistHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const SkeletonBox(width: 200, height: 200, borderRadius: 24),
          const SizedBox(height: 24),
          const SkeletonBox(width: 240, height: 28, borderRadius: 6),
          const SizedBox(height: 12),
          const SkeletonBox(width: 150, height: 16, borderRadius: 4),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SkeletonBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 24),
              const SkeletonBox(width: 64, height: 64, borderRadius: 32),
              const SizedBox(width: 24),
              const SkeletonBox(width: 48, height: 48, borderRadius: 24),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
