import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/models/track.dart';
import '../../core/providers.dart';

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}

class LyricsPanel extends ConsumerStatefulWidget {
  final Track track;
  const LyricsPanel({super.key, required this.track});

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _lyricLines = [];
  int _activeIndex = -1;
  bool _isLoading = true;
  String? _lyrics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    String? result;
    try {
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 8)));
      String cleanTitle = widget.track.title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
      String query = cleanTitle;
      if (widget.track.artist.isNotEmpty && widget.track.artist.toLowerCase() != 'unknown') {
        query = '$cleanTitle ${widget.track.artist}'.trim();
      }
      
      final res = await dio.get(
        'https://lrclib.net/api/search',
        queryParameters: {'q': query},
      );
      
      if (res.statusCode == 200) {
        final items = res.data as List;
        if (items.isNotEmpty) {
          for (final item in items) {
            final synced = item['syncedLyrics']?.toString();
            if (synced != null && synced.isNotEmpty) {
              result = synced;
              break;
            }
          }
          if (result == null) {
            result = items.first['plainLyrics']?.toString();
            if (result != null && result.isNotEmpty) {
              // Switch to plain tab automatically if no synced lyrics
              _tabController.animateTo(1);
            }
          }
        }
      }
    } catch (e) {
      print('[LyricsPanel] LRCLib direct error: $e');
    }

    // Fallback to music service (e.g. yt-dlp extraction)
    if (result == null) {
      result = await ref.read(musicServiceProvider).getLyrics(widget.track.youtubeId);
    }

    if (mounted) {
      setState(() {
        _lyrics = result;
        _isLoading = false;
        if (_lyrics != null) {
          _lyricLines = _parseLrc(_lyrics!);
          if (_lyricLines.isEmpty && _lyrics!.isNotEmpty) {
             _tabController.animateTo(1);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<LyricLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final List<LyricLine> result = [];
    // More robust regex: supports [mm:ss.xx], [m:ss.xxx], [mm:ss], etc.
    final regExp = RegExp(r'\[(\d+):(\d+)(?:[:\.](\d+))?\]');

    for (var line in lines) {
      final matches = regExp.allMatches(line);
      if (matches.isNotEmpty) {
        final text = line.replaceAll(regExp, '').trim();
        if (text.isEmpty) continue;

        for (var match in matches) {
           final m = int.parse(match.group(1)!);
           final s = int.parse(match.group(2)!);
           final msStr = match.group(3) ?? "0";
           int ms = int.parse(msStr);
           
           // Normalize milliseconds (if 2 digits, it's centiseconds; if 3, it's ms)
           if (msStr.length == 2) ms *= 10;
           else if (msStr.length == 1) ms *= 100;

           final time = Duration(minutes: m, seconds: s, milliseconds: ms);
           result.add(LyricLine(time, text));
        }
      }
    }
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients || index == -1) return;
    
    // Smooth scrolling to center the active line
    final double screenHeight = MediaQuery.of(context).size.height;
    const double linePadding = 40.0; // vertical padding (20 on top, 20 on bottom)
    const double estimatedLineHeight = 84.0; // Adjust based on font size and height
    
    final double targetOffset = (index * estimatedLineHeight) - (screenHeight * 0.4) + linePadding;
    
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.track.effectiveThumbnailUrl, width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 120, cacheHeight: 120),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.track.title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(widget.track.artist, style: TextStyle(color: onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: onSurface.withOpacity(0.5),
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: "SYNCED"),
              Tab(text: "PLAIN"),
            ],
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSyncedLyrics(theme, onSurface),
                    _buildPlainLyrics(context, theme, onSurface),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedLyrics(ThemeData theme, Color color) {
    if (_lyrics == null || _lyrics!.isEmpty) return _buildNoLyrics(color);
    if (_lyricLines.isEmpty) return _buildPlainLyrics(context, theme, color);

    final player = ref.read(audioHandlerProvider).player;
    
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        
        int newIndex = -1;
        for (int i = 0; i < _lyricLines.length; i++) {
          if (position >= _lyricLines[i].time) {
            newIndex = i;
          } else {
            break;
          }
        }

        if (newIndex != _activeIndex) {
          _activeIndex = newIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(_activeIndex));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
          itemCount: _lyricLines.length,
          itemBuilder: (context, index) {
            final line = _lyricLines[index];
            final bool isActive = index == _activeIndex;
            
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isActive ? 1.0 : 0.3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? theme.primaryColor : color,
                    fontSize: isActive ? 32 : 26,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildNoLyrics(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 64, color: color.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("No synced lyrics found for this song.", style: TextStyle(color: color.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildPlainLyrics(BuildContext context, ThemeData theme, Color color, [String? existingLyrics]) {
    final rawLyrics = existingLyrics ?? _lyrics;
    if (rawLyrics == null || rawLyrics.isEmpty) return _buildNoLyrics(color);

    final cleanLyrics = rawLyrics.replaceAll(RegExp(r'\[\d+:\d+(?:[:\.]\d+)?\]'), '').trim();
    
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 120),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              cleanLyrics,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 20,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 32, right: 32,
          child: FloatingActionButton.extended(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: cleanLyrics));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lyrics copied to clipboard!")));
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.black),
            label: const Text("Copy Plain Text", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: theme.primaryColor,
          ),
        )
      ],
    );
  }
}

void showLyrics(BuildContext context, Track track) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: LyricsPanel(track: track),
    ),
  );
}
