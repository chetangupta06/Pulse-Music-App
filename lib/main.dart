import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/podcasts/podcasts_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/player/bottom_player.dart';
import 'core/db/isar_db.dart';
import 'core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/settings_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/library/user_playlists_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/onboarding_screen.dart';
import 'features/player/mini_player_screen.dart';
import 'core/settings.dart';
import 'package:media_kit/media_kit.dart' hide Track;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  await IsarDb.instance.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const PULSEApp(),
    )
  );
}

class PULSEApp extends ConsumerWidget {
  const PULSEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    final theme = AppTheme.getTheme(themeMode);
    final isMiniPlayer = ref.watch(isMiniPlayerProvider);

    return MaterialApp(
      title: 'PULSE',
      theme: theme,
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
      ),
      debugShowCheckedModeBanner: false,
      home: isMiniPlayer ? const MiniPlayerScreen() : const MainLayout(),
    );
  }
}

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navIndex = ref.watch(navIndexProvider);
    final userName = ref.watch(settingsProvider).userName;
    
    if (userName == null || userName.isEmpty) {
       return const OnboardingScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: IndexedStack(
                    index: navIndex,
                    children: const [
                      HomeScreen(),
                      PodcastsScreen(),
                      SearchScreen(),
                      UserPlaylistsScreen(),
                      FavoritesScreen(),
                      DownloadsScreen(),
                      SettingsScreen(),
                      ProfileScreen(),
                    ],
                  ),
                )
              ],
            ),
          ),
          const BottomPlayer(),
        ],
      ),
    );
  }
}

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 20, 32),
            child: Row(
              children: [
                _AnimatedBrandLogo(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12, top: 8),
                    child: Text("BROWSE", style: theme.textTheme.labelMedium?.copyWith(color: onSurface.withOpacity(0.5), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  ),
                  _SidebarItem(
                    icon: Icons.explore_rounded, 
                    label: "Discover", 
                    isSelected: currentIndex == 0, 
                    onTap: () => ref.read(navIndexProvider.notifier).setIndex(0),
                    trailing: currentIndex == 0 ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          // Invalidate providers to trigger a refresh
                          ref.invalidate(recommendationsProvider);
                          ref.invalidate(playlistSearchResultsProvider);
                          ref.invalidate(topArtistsProvider);
                        },
                        child: const Icon(Icons.refresh_rounded, size: 18),
                      ),
                    ) : null,
                  ),
                  _SidebarItem(icon: Icons.mic_rounded, label: "Podcasts", isSelected: currentIndex == 1, onTap: () => ref.read(navIndexProvider.notifier).setIndex(1)),
                  _SidebarItem(icon: Icons.search_rounded, label: "Search", isSelected: currentIndex == 2, onTap: () => ref.read(navIndexProvider.notifier).setIndex(2)),
                  
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: Text("LIBRARY", style: theme.textTheme.labelMedium?.copyWith(color: onSurface.withOpacity(0.5), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  ),
                  _SidebarItem(icon: Icons.favorite_rounded, label: "Liked Songs", isSelected: currentIndex == 4, onTap: () => ref.read(navIndexProvider.notifier).setIndex(4)),
                  _SidebarItem(icon: Icons.format_list_bulleted_rounded, label: "Playlists", isSelected: currentIndex == 3, onTap: () => ref.read(navIndexProvider.notifier).setIndex(3)),
                  _SidebarItem(icon: Icons.download_done_rounded, label: "Downloads", isSelected: currentIndex == 5, onTap: () => ref.read(navIndexProvider.notifier).setIndex(5)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Profile and Settings at Bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SidebarItem(
              icon: Icons.person_outline_rounded, 
              label: "Profile", 
              isSelected: currentIndex == 7, 
              onTap: () => ref.read(navIndexProvider.notifier).setIndex(7)
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SidebarItem(
              icon: Icons.settings_outlined, 
              label: "Settings", 
              isSelected: currentIndex == 6, 
              onTap: () => ref.read(navIndexProvider.notifier).setIndex(6)
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarItem({required this.label, this.icon, this.isSelected = false, required this.onTap, this.trailing});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final isHovered = _isHovering && !isActive;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final onSurface = theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withOpacity(0.08)
                : isHovered
                    ? onSurface.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Icon(
                    widget.icon,
                    color: isActive ? primaryColor : (isHovered ? onSurface : onSurface.withOpacity(0.6)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
              ] else
                const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: isActive ? primaryColor : (isHovered ? onSurface : onSurface.withOpacity(0.8)),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBrandLogo extends StatefulWidget {
  @override
  State<_AnimatedBrandLogo> createState() => _AnimatedBrandLogoState();
}

class _AnimatedBrandLogoState extends State<_AnimatedBrandLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, const Color(0xFF6366F1)], // Teal to Indigo
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 10 + (_controller.value * 5),
                    spreadRadius: _controller.value * 2,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [theme.colorScheme.onSurface, theme.primaryColor, theme.colorScheme.onSurface],
                  stops: [0.0, _controller.value, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Text(
                "PULSE",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontSize: 22,
                  color: Colors.white, // Required for ShaderMask to work properly
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
