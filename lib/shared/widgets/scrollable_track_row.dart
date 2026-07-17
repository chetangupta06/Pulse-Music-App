import 'package:flutter/material.dart';
import '../../core/models/track.dart';
import 'track_card.dart';
import '../theme/app_theme.dart';

class ScrollableTrackRow extends StatefulWidget {
  final List<Track> tracks;
  final int rows;
  final String? title;
  const ScrollableTrackRow({super.key, required this.tracks, this.rows = 1, this.title});

  @override
  State<ScrollableTrackRow> createState() => _ScrollableTrackRowState();
}

class _ScrollableTrackRowState extends State<ScrollableTrackRow> {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollAmount = 600.0;
  bool _showLeft = false;
  bool _showRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateChevrons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateChevrons());
  }

  void _updateChevrons() {
    if (!_scrollController.hasClients) return;
    
    final offset = _scrollController.offset;
    final max = _scrollController.position.maxScrollExtent;
    
    setState(() {
       _showLeft = offset > 0;
       _showRight = offset < max;
    });
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      final target = _scrollController.offset - 500;
      _scrollController.animateTo(
        target < 0 ? 0.0 : target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      final target = _scrollController.offset + 500;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target > max ? max : target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateChevrons);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tracks.isEmpty) {
      return const SizedBox(height: 250, child: Center(child: Text("No tracks found", style: TextStyle(color: Colors.white54))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title!, 
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
                      onPressed: _showLeft ? _scrollLeft : null,
                      color: _showLeft ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 28),
                      onPressed: _showRight ? _scrollRight : null,
                      color: _showRight ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(
          height: widget.rows == 2 ? 380 : 190,
          child: GridView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.rows,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              childAspectRatio: 1.516,
            ),
            itemCount: widget.tracks.length,
            itemBuilder: (context, index) {
              return TrackCard(track: widget.tracks[index], rightMargin: 0);
            },
          ),
        ),
      ],
    );
  }
}
