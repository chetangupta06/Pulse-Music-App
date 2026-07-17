import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/models/app_playlist.dart';
import '../../shared/widgets/scrollable_track_row.dart';
import '../../core/settings.dart';
import '../../shared/widgets/playlist_card.dart';
import '../../shared/widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSections = ref.watch(settingsProvider).activeHomeSections;
    final userName = ref.watch(settingsProvider).userName ?? "Music Lover";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: _AnimatedGreeting(userName: userName),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([


                if (activeSections.contains("Recommendations")) ...[
                  _buildRecommendationsGrid(context, ref, "Recommended For You"),
                  const SizedBox(height: 36),
                  _buildLiveGrid(context, ref, "Latest New Hindi Songs 2026", "New Releases"),
                  const SizedBox(height: 36),
                ],
                
                if (activeSections.contains("Trending Playlists")) ...[
                  _buildLivePlaylistGrid(context, ref, "Bollywood", "Trending Playlists"),
                  const SizedBox(height: 36),
                ],

                if (activeSections.contains("Desi Hot Hits")) ...[
                  _buildLiveGrid(context, ref, "Bollywood Hits 2026", "Desi Hot Hits"),
                  const SizedBox(height: 36),
                ],
                
                if (activeSections.contains("Ghazal & Sufi Classics")) ...[
                  _buildLiveGrid(context, ref, "Best Of Ghazals Hindi", "Ghazal & Sufi Classics"),
                  const SizedBox(height: 36),
                ],
                
                if (activeSections.contains("Geetmala Legends")) ...[
                  _buildLiveGrid(context, ref, "Kishore Kumar Lata Mangeshkar Hit Songs", "Geetmala Legends"),
                  const SizedBox(height: 36),
                ],

                // Popular Artists at the bottom of Discover
                if (activeSections.contains("Popular Artists")) ...[
                  _buildTopArtistsRow(context, ref, "Popular Artists"),
                ],
              ]),
            ),
          ),
          // Padding for bottom player
          const SliverToBoxAdapter(child: SizedBox(height: 120))
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, {bool isSelected = false}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? theme.primaryColor.withOpacity(0.3) : theme.dividerColor),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20, top: 12),
      child: Text(
        title, 
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        )
      )
    );
  }

  Widget _buildLiveGrid(BuildContext context, WidgetRef ref, String query, String title) {
    final searchAsync = ref.watch(searchResultsProvider(query));

    return searchAsync.when(
      data: (tracks) {
        return ScrollableTrackRow(tracks: tracks, title: title);
      },
      loading: () => SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => const SizedBox(width: 140, child: SkeletonTrackCard()),
        ),
      ),
      error: (e, st) => SizedBox(
        height: 190,
        child: Center(child: Text("Error fetching records: \$e", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildLivePlaylistGrid(BuildContext context, WidgetRef ref, String query, String title) {
    final searchAsync = ref.watch(playlistSearchResultsProvider(query));
    return searchAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) return const SizedBox(height: 250, child: Center(child: Text("No playlists found")));
        return _ScrollablePlaylistRow(playlists: playlists, title: title);
      },
      loading: () => SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => const SizedBox(
             width: 280, 
             child: SkeletonLoader(child: SkeletonBox(borderRadius: 16)),
          ),
        ),
      ),
      error: (e, st) => const SizedBox(height: 190, child: Center(child: Text("Error loading playlists", style: TextStyle(color: Colors.red)))),
    );
  }

  Widget _buildRecommendationsGrid(BuildContext context, WidgetRef ref, String title) {
    final asyncTracks = ref.watch(recommendationsProvider);
    return asyncTracks.when(
      data: (tracks) {
         if (tracks.isEmpty) return const SizedBox(height: 380, child: Center(child: Text("Start playing music to get recommendations!", style: TextStyle(color: Colors.white54))));
         return ScrollableTrackRow(tracks: tracks, rows: 2, title: title);
      },
      loading: () => SizedBox(
        height: 380,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) => const SizedBox(
            width: 140,
            child: Column(
              children: [
                Expanded(child: SkeletonTrackCard()),
                SizedBox(height: 16),
                Expanded(child: SkeletonTrackCard()),
              ],
            ),
          ),
        ),
      ),
      error: (e, st) => const SizedBox(height: 380, child: Center(child: Text("Error generating history map", style: TextStyle(color: Colors.red)))),
    );
  }

  Widget _buildTopArtistsRow(BuildContext context, WidgetRef ref, String title) {
    final asyncArtists = ref.watch(topArtistsProvider);
    return asyncArtists.when(
      data: (artists) {
         if (artists.isEmpty) return const SizedBox.shrink();
         return _ScrollableArtistsRow(artists: artists, ref: ref, title: title);
      },
      loading: () => SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(width: 32),
          itemBuilder: (context, index) => const SkeletonLoader(
             child: Column(
                children: [
                   SkeletonBox(width: 130, height: 130, borderRadius: 65),
                   SizedBox(height: 12),
                   SkeletonBox(width: 100, height: 14, borderRadius: 4),
                ]
             )
          ),
        ),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _ScrollablePlaylistRow extends StatefulWidget {
  final List<AppPlaylist> playlists;
  final String title;
  const _ScrollablePlaylistRow({required this.playlists, required this.title});

  @override
  State<_ScrollablePlaylistRow> createState() => _ScrollablePlaylistRowState();
}

class _ScrollablePlaylistRowState extends State<_ScrollablePlaylistRow> {
  final ScrollController _controller = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _showLeft = _controller.offset > 10;
      _showRight = _controller.offset < _controller.position.maxScrollExtent - 10;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _showLeft ? () {
                      _controller.animateTo(
                        (_controller.offset - 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showLeft ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _showRight ? () {
                      _controller.animateTo(
                        (_controller.offset + 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showRight ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: GridView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              childAspectRatio: 1.516,
            ),
            itemCount: widget.playlists.length,
            itemBuilder: (context, index) {
              return PlaylistCard(playlist: widget.playlists[index], rightMargin: 0);
            },
          ),
        ),
      ],
    );
  }
}

class _ScrollableArtistsRow extends StatefulWidget {
  final List<dynamic> artists;
  final WidgetRef ref;
  final String title;
  const _ScrollableArtistsRow({required this.artists, required this.ref, required this.title});

  @override
  State<_ScrollableArtistsRow> createState() => _ScrollableArtistsRowState();
}

class _ScrollableArtistsRowState extends State<_ScrollableArtistsRow> {
  final ScrollController _controller = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    setState(() {
      _showLeft = _controller.offset > 10;
      _showRight = _controller.offset < _controller.position.maxScrollExtent - 10;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _showLeft ? () {
                      _controller.animateTo(
                        (_controller.offset - 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showLeft ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _showRight ? () {
                      _controller.animateTo(
                        (_controller.offset + 500).clamp(0.0, _controller.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    } : null,
                    color: _showRight ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.artists.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 32),
                child: _ArtistCard(artist: widget.artists[index], ref: widget.ref),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArtistCard extends StatefulWidget {
  final dynamic artist;
  final WidgetRef ref;
  const _ArtistCard({required this.artist, required this.ref});

  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    final name = a['artist']?.toString() ?? a['name']?.toString() ?? 'Artist';
    final thumbs = a['thumbnails'] as List?;
    final thumbUrl = (thumbs != null && thumbs.isNotEmpty) ? thumbs.last['url']?.toString() : null;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              widget.ref.read(navIndexProvider.notifier).setIndex(2);
              widget.ref.read(searchQueryProvider.notifier).setQuery(name);
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isHovered ? 135 : 130, 
                  height: isHovered ? 135 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: thumbUrl != null ? DecorationImage(image: NetworkImage(thumbUrl), fit: BoxFit.cover) : null,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(isHovered ? 0.5 : 0.3), 
                        blurRadius: isHovered ? 20 : 15, 
                        spreadRadius: isHovered ? 2 : -2
                      )
                    ]
                  ),
                  child: thumbUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white54) : null,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    width: 140,
                    child: Text(
                      name, 
                      textAlign: TextAlign.center, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(
                        color: isHovered ? Theme.of(context).primaryColor : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (a['isCustom'] == true)
             Positioned(
               top: 0, right: 0,
               child: AnimatedOpacity(
                 duration: const Duration(milliseconds: 200),
                 opacity: isHovered ? 1.0 : 0.0,
                 child: GestureDetector(
                   onTap: () => widget.ref.read(settingsProvider.notifier).removeCustomArtist(name),
                   child: Container(
                     decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                     padding: const EdgeInsets.all(4),
                     child: const Icon(Icons.close, size: 16, color: Colors.white),
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}

class _AnimatedGreeting extends StatefulWidget {
  final String userName;
  const _AnimatedGreeting({required this.userName});

  @override
  State<_AnimatedGreeting> createState() => _AnimatedGreetingState();
}

class _AnimatedGreetingState extends State<_AnimatedGreeting> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.2, end: 0.3).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [theme.primaryColor, theme.colorScheme.secondary, theme.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "Hello, ${widget.userName}",
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
