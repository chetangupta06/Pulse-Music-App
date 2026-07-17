import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/hover_container.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/track_card.dart';
import '../../shared/widgets/track_context_menu.dart';
import '../../features/playlist/playlist_screen.dart';
import '../../core/models/track.dart';

final _searchInputProvider = StateProvider.autoDispose<String>((ref) => '');
final _showSuggestionsProvider = StateProvider.autoDispose<bool>((ref) => false);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = ref.read(searchQueryProvider);
      if (q.isNotEmpty) {
        _searchController.text = q;
        ref.read(_searchInputProvider.notifier).state = q;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;
    _searchFocus.unfocus();
    ref.read(_showSuggestionsProvider.notifier).state = false;
    ref.read(searchQueryProvider.notifier).setQuery(value);
    ref.read(searchHistoryProvider.notifier).add(value);
    
    // Auto-switch to podcasts filter if the user explicitly types 'podcast'
    if (value.toLowerCase().contains('podcast')) {
      ref.read(searchFilterProvider.notifier).setFilter('podcasts');
    } else if (ref.read(searchFilterProvider) == 'podcasts') {
      // Switch back to all if they clear podcast from query to avoid confusion
      ref.read(searchFilterProvider.notifier).setFilter('all');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final history = ref.watch(searchHistoryProvider);
    final inputText = ref.watch(_searchInputProvider);
    final showSuggestions = ref.watch(_showSuggestionsProvider);
    final filter = ref.watch(searchFilterProvider);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Fixed search header
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmartSearchBar(context, ref),
                const SizedBox(height: 16),
                // Filter Chips
                if (!showSuggestions && query.isNotEmpty)
                  Row(
                    children: [
                      _buildFilterChip('All', 'all', filter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Songs', 'songs', filter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Playlists', 'playlists', filter),
                      const SizedBox(width: 8),
                      _buildFilterChip('Podcasts', 'podcasts', filter),
                    ],
                  ),
              ],
            ),
          ),
          
          // Scrollable results / suggestions
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (showSuggestions && inputText.isNotEmpty)
                  _buildSuggestions(context, ref, inputText)
                else if (query.isEmpty && history.isNotEmpty)
                  _buildHistory(context, ref, history)
                else if (query.isEmpty && history.isEmpty)
                  SliverFillRemaining(child: Center(child: Icon(Icons.search, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05))))
                else
                  _buildUnifiedResults(context, ref, query, filter),
                  
                const SliverToBoxAdapter(child: SizedBox(height: 120))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(searchFilterProvider.notifier).setFilter(value),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      selectedColor: theme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? theme.primaryColor : Colors.transparent),
      ),
    );
  }

  Widget _buildSmartSearchBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (val) {
          ref.read(_searchInputProvider.notifier).state = val;
          if (val.isNotEmpty) {
            ref.read(_showSuggestionsProvider.notifier).state = true;
          } else {
            ref.read(_showSuggestionsProvider.notifier).state = false;
            ref.read(searchQueryProvider.notifier).setQuery('');
          }
        },
        onSubmitted: _submitSearch,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: "What do you want to listen to?",
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: theme.primaryColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                onPressed: () {
                  _searchController.clear();
                  ref.read(_searchInputProvider.notifier).state = '';
                  ref.read(_showSuggestionsProvider.notifier).state = false;
                  ref.read(searchQueryProvider.notifier).setQuery("");
                  _searchFocus.unfocus();
                },
              ) 
            : null,
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, WidgetRef ref, String query) {
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
    
    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.search, size: 20),
                  title: Text(suggestion, style: const TextStyle(fontSize: 16)),
                  onTap: () {
                    _searchController.text = suggestion;
                    _submitSearch(suggestion);
                  },
                );
              },
              childCount: suggestions.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildHistory(BuildContext context, WidgetRef ref, List<String> history) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Searches",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                    child: Text(
                      "Clear All",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = history[index];
                return HoverContainer(
                  onTap: () {
                    _searchController.text = item;
                    _submitSearch(item);
                  },
                  hoverDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 24, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(item, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65), fontSize: 16))),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
                          onPressed: () => ref.read(searchHistoryProvider.notifier).remove(item),
                        ),
                        Icon(Icons.north_west, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
                      ],
                    ),
                  ),
                );
              },
              childCount: history.length,
            ),
          ),
        ),
      ]
    );
  }

  Widget _buildUnifiedResults(BuildContext context, WidgetRef ref, String query, String filter) {
    final searchAsync = ref.watch(searchResultsUnifiedProvider(query));

    return searchAsync.when(
      data: (results) {
         if (results.tracks.isEmpty && results.playlists.isEmpty && results.podcasts.isEmpty && results.episodes.isEmpty) {
           return SliverFillRemaining(child: Center(child: Text("No results found for '$query'.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)))));
         }
         
         final showSongs = filter == 'all' || filter == 'songs';
         final showPlaylists = filter == 'all' || filter == 'playlists';
         final showPodcasts = filter == 'podcasts';

         return SliverPadding(
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
           sliver: SliverList(
             delegate: SliverChildListDelegate([
               if (showSongs && results.tracks.isNotEmpty) ...[
                 _buildSectionHeader(context, "Songs"),
                 Container(
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.surface,
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                   ),
                   child: ListView.separated(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: results.tracks.length,
                     separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                     itemBuilder: (context, index) {
                       final track = results.tracks[index];
                       return HoverContainer(
                         onTap: () => ref.read(queueProvider.notifier).playAll(results.tracks, startIndex: index),
                         hoverDecoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                           borderRadius: index == 0 
                               ? const BorderRadius.vertical(top: Radius.circular(16)) 
                               : (index == results.tracks.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
                         ),
                         child: ListTile(
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           leading: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: track.thumbnailUrl.isNotEmpty 
                                ? Image.network(track.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover)
                                : Container(width: 48, height: 48, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.music_note)),
                           ),
                           title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                           subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                           trailing: TrackContextMenu(track: track, child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                         ),
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 48),
               ],
               if (showPlaylists && results.playlists.isNotEmpty) ...[
                 _buildSectionHeader(context, "Playlists"),
                 GridView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                     maxCrossAxisExtent: 180,
                     mainAxisSpacing: 20,
                     crossAxisSpacing: 16,
                     childAspectRatio: 0.68,
                   ),
                   itemCount: results.playlists.length,
                   itemBuilder: (context, index) {
                      final p = results.playlists[index];
                      return HoverContainer(
                        hoverDecoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                           borderRadius: BorderRadius.circular(16),
                        ),
                        onTap: () {
                           Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(playlist: p)));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  image: p.thumbnailUrl.isNotEmpty 
                                    ? DecorationImage(image: NetworkImage(p.thumbnailUrl), fit: BoxFit.cover)
                                    : null,
                                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: p.thumbnailUrl.isEmpty 
                                  ? Icon(Icons.playlist_play, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15))
                                  : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(p.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text("Playlist", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                            ),
                          ],
                        ),
                      );
                   },
                 ),
               ],
               if (showPodcasts && results.episodes.isNotEmpty) ...[
                 _buildSectionHeader(context, "Podcast Episodes"),
                 Container(
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.surface,
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                   ),
                   child: ListView.separated(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: results.episodes.length,
                     separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                     itemBuilder: (context, index) {
                       final track = results.episodes[index];
                       return HoverContainer(
                         onTap: () => ref.read(queueProvider.notifier).playAll(results.episodes, startIndex: index),
                         hoverDecoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                           borderRadius: index == 0 
                               ? const BorderRadius.vertical(top: Radius.circular(16)) 
                               : (index == results.episodes.length - 1 ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
                         ),
                         child: ListTile(
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           leading: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: track.thumbnailUrl.isNotEmpty 
                                ? Image.network(track.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover)
                                : Container(width: 48, height: 48, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.mic)),
                           ),
                           title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                           subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                           trailing: TrackContextMenu(track: track, child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                         ),
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 48),
               ],
               if (showPodcasts && results.podcasts.isNotEmpty) ...[
                 _buildSectionHeader(context, "Podcast Shows"),
                 GridView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                     maxCrossAxisExtent: 180,
                     mainAxisSpacing: 20,
                     crossAxisSpacing: 16,
                     childAspectRatio: 0.68,
                   ),
                   itemCount: results.podcasts.length,
                   itemBuilder: (context, index) {
                      final p = results.podcasts[index];
                      return HoverContainer(
                        hoverDecoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                           borderRadius: BorderRadius.circular(16),
                        ),
                        onTap: () {
                           Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistScreen(playlist: p)));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  image: p.thumbnailUrl.isNotEmpty 
                                    ? DecorationImage(image: NetworkImage(p.thumbnailUrl), fit: BoxFit.cover)
                                    : null,
                                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: p.thumbnailUrl.isEmpty 
                                  ? Icon(Icons.mic, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15))
                                  : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(p.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(p.author, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                   },
                 ),
               ]
             ])
           ),
         );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonListRow(),
            ),
            childCount: 10,
          ),
        ),
      ),
      error: (e, st) => SliverFillRemaining(child: Center(child: Text("Error fetching records: $e", style: TextStyle(color: Theme.of(context).colorScheme.error)))),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          title, 
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)
        ),
    );
  }
}
