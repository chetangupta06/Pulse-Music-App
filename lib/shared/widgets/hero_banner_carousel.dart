import 'package:flutter/material.dart';

import '../../core/models/festival_event.dart';
import '../../core/models/playlist.dart';
import 'desi_card.dart';

class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({
    super.key,
    required this.playlists,
    required this.festivals,
  });

  final List<Playlist> playlists;
  final List<FestivalEvent> festivals;

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroes = <_HeroBannerItem>[
      for (final playlist in widget.playlists.take(3))
        _HeroBannerItem(
          title: playlist.title,
          subtitle: playlist.subtitle,
          eyebrow: playlist.curator,
          gradient: playlist.gradient,
        ),
      for (final festival in widget.festivals.take(2))
        _HeroBannerItem(
          title: festival.name,
          subtitle: festival.tagline,
          eyebrow:
              '${festival.date.difference(DateTime.now()).inDays} days away',
          gradient: festival.palette,
        ),
    ];

    return Column(
      children: <Widget>[
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            itemCount: heroes.length,
            onPageChanged: (int value) => setState(() => _page = value),
            itemBuilder: (BuildContext context, int index) {
              final item = heroes[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == heroes.length - 1 ? 0 : 18,
                ),
                child: DesiCard(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradient,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Chip(
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        label: Text(
                          item.eyebrow,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          item.subtitle,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            heroes.length,
            (int index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _page == index ? 1 : 0.28,
                    ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBannerItem {
  const _HeroBannerItem({
    required this.title,
    required this.subtitle,
    required this.eyebrow,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String eyebrow;
  final List<Color> gradient;
}
