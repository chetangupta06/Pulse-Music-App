import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/downloads/presentation/downloads_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/playlists/presentation/playlists_screen.dart';
import 'navigation_sidebar.dart';
import 'player_bar.dart';
import 'right_panel.dart';
import 'top_search_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(currentDestinationProvider);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.home,
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.discover,
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.library,
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.downloads,
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.playlists,
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () =>
            ref.read(currentDestinationProvider.notifier).state =
                AppDestination.community,
        const SingleActivator(LogicalKeyboardKey.space): () =>
            ref.read(playbackControllerProvider).togglePlayPause(),
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              const _BackgroundMotif(),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          const NavigationSidebar(),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final showRightPanel =
                                    constraints.maxWidth > 1100;
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        children: <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              24,
                                              24,
                                              24,
                                              0,
                                            ),
                                            child: TopSearchBar(),
                                          ),
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              child: KeyedSubtree(
                                                key: ValueKey<AppDestination>(
                                                    destination),
                                                child: _buildScreen(
                                                  destination,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (showRightPanel) const RightPanel(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PlayerBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(AppDestination destination) {
    return switch (destination) {
      AppDestination.home => const HomeScreen(),
      AppDestination.discover => const DiscoverScreen(),
      AppDestination.library => const LibraryScreen(),
      AppDestination.downloads => const DownloadsScreen(),
      AppDestination.playlists => const PlaylistsScreen(),
      AppDestination.community => const CommunityScreen(),
    };
  }
}

class _BackgroundMotif extends StatelessWidget {
  const _BackgroundMotif();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -40,
            child: _GlowCircle(
              size: 240,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -110,
            left: 260,
            child: _GlowCircle(
              size: 320,
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _GlowCircle(
              size: 180,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
