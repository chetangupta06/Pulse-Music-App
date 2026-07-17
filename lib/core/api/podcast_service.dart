import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:podcast_search/podcast_search.dart';
import '../models/track.dart';
import '../models/app_playlist.dart';
import '../providers.dart';
import '../settings.dart';
import 'youtube_dlp_service.dart';

class PodcastService {
  final Search _search = Search();

  /// Get top trending podcasts
  Future<List<Item>> getTrendingPodcasts({int limit = 20}) async {
    final results = await _search.charts(limit: limit);
    return results.items;
  }

  /// Search podcasts by query
  Future<List<Item>> searchPodcasts(String query, {int limit = 20}) async {
    final results = await _search.search(query, limit: limit);
    return results.items;
  }

  /// Fetch a podcast's feed and parse its episodes into Desi Chaska Tracks
  Future<Map<String, dynamic>> loadPodcast(String feedUrl) async {
    try {
      final podcast = await Feed.loadFeed(url: feedUrl);
      
      final tracks = podcast.episodes.map((ep) {
        return Track()
          ..id = ep.guid ?? ep.title ?? ''
          // IMPORTANT: we inject the raw audio stream URL straight into youtubeId
          // so the media engine bypasses extraction and streams it directly.
          ..youtubeId = ep.contentUrl ?? ''
          ..title = Track.decodeHtml(ep.title ?? 'Unknown Episode')
          ..artist = Track.decodeHtml(podcast.title ?? 'Unknown Podcast')
          // Fallback to the podcast show's master art if episode art is missing
          ..thumbnailUrl = ep.imageUrl ?? podcast.image ?? ''
          ..durationMs = (ep.duration?.inMilliseconds ?? 0)
          ..trackType = 'podcast';
      }).where((t) => t.youtubeId.isNotEmpty).toList();

      return {
        'podcast': podcast,
        'tracks': tracks,
      };
    } catch (e) {
      throw Exception('Failed to load podcast feed: $e');
    }
  }
}

final podcastServiceProvider = Provider<PodcastService>((ref) {
  return PodcastService();
});

// A provider to fetch top trending podcasts
final trendingPodcastsProvider = FutureProvider<List<Item>>((ref) async {
  final service = ref.watch(podcastServiceProvider);
  return service.getTrendingPodcasts(limit: 15);
});

// YouTube Music curated podcast providers

String _appendLang(String query, AppSettings settings) {
  if (settings.podcastLanguage == 'Any') return query;
  return "$query ${settings.podcastLanguage}";
}

final youtubeRecommendedEpisodesProvider = FutureProvider<List<Track>>((ref) async {
  final musicService = ref.watch(musicServiceProvider);
  final db = ref.read(isarDbProvider);
  final settings = ref.watch(settingsProvider);
  final queries = db.getPodcastRecommendations();
  
  final fetchCount = queries.length > 2 ? 2 : queries.length;
  final results = await Future.wait(
      queries.take(fetchCount).map((q) => musicService.searchEpisodes(_appendLang(q, settings)))
  );
  
  final List<Track> combined = [];
  for (var res in results) {
     // Filter out shorts or short clips (< 5 mins), but allow 0 since YTMusic API often returns null duration for valid episodes
     final validEpisodes = res.where((t) {
        if (t.durationMs > 0 && t.durationMs < 300000) return false;
        final title = t.title.toLowerCase();
        if (title.contains('#short') || title.contains('shorts') || title.contains('summary') || title.contains('reaction') || title.contains('minute')) return false;
        return true;
     });
     combined.addAll(validEpisodes);
  }
  
  combined.shuffle();
  return combined.take(15).toList();
});

final dynamicPodcastProvider = FutureProvider.family<List<AppPlaylist>, String>((ref, query) async {
  final musicService = ref.watch(musicServiceProvider);
  
  final rawResults = await musicService.searchPodcasts(query);
  
  // Extract base keywords for strict filtering
  final baseQuery = query.replaceAll(' podcast', '').toLowerCase().trim();
  final keywords = baseQuery.split(' ').where((w) => w.length > 2).toList();
  
  if (keywords.isEmpty) return rawResults;
  
  return rawResults.where((p) {
    final title = p.title.toLowerCase();
    final author = p.author.toLowerCase();
    return keywords.any((kw) => title.contains(kw) || author.contains(kw));
  }).toList();
});

final dynamicPodcastEpisodesProvider = FutureProvider.family<List<Track>, String>((ref, query) async {
  final musicService = ref.watch(musicServiceProvider);
  
  final rawResults = await musicService.searchEpisodes(query);
  
  final filtered = rawResults.where((t) {
    if (t.durationMs > 0 && t.durationMs < 300000) return false;
    final title = t.title.toLowerCase();
    if (title.contains('#short') || title.contains('shorts') || title.contains('summary') || title.contains('reaction') || title.contains('minute')) return false;
    return true;
  }).toList();
  
  final baseQuery = query.replaceAll(' podcast', '').toLowerCase().trim();
  final keywords = baseQuery.split(' ').where((w) => w.length > 2).toList();
  
  if (keywords.isEmpty) return filtered;
  
  return filtered.where((p) {
    final title = p.title.toLowerCase();
    final artist = p.artist.toLowerCase();
    return keywords.any((kw) => title.contains(kw) || artist.contains(kw));
  }).toList();
});
