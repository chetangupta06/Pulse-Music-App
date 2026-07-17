import 'package:flutter/material.dart';

/// A small animated audio waveform indicator that shows the currently playing track.
/// Displays 3 bars that animate up and down continuously when [isPlaying] is true.
class NowPlayingWave extends StatefulWidget {
  final double size;
  final Color? color;
  final bool isPlaying;

  const NowPlayingWave({
    super.key,
    this.size = 16,
    this.color,
    this.isPlaying = true,
  });

  @override
  State<NowPlayingWave> createState() => _NowPlayingWaveState();
}

class _NowPlayingWaveState extends State<NowPlayingWave>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _barCount = 3;
  // Each bar has a different duration for a natural feel
  static const _durations = [450, 550, 400];
  // Each bar has a different min/max height ratio
  static const _minHeights = [0.25, 0.35, 0.20];
  static const _maxHeights = [1.0, 0.75, 0.90];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (i) {
      return AnimationController(
        duration: Duration(milliseconds: _durations[i]),
        vsync: this,
      );
    });

    _animations = List.generate(_barCount, (i) {
      final controller = _controllers[i];
      final animation = Tween<double>(
        begin: _minHeights[i],
        end: _maxHeights[i],
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      // Stagger the start of each bar slightly
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted && widget.isPlaying) {
          controller.repeat(reverse: true);
        }
      });

      return animation;
    });
  }

  @override
  void didUpdateWidget(NowPlayingWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        for (var c in _controllers) {
          c.repeat(reverse: true);
        }
      } else {
        for (var c in _controllers) {
          c.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    final barWidth = widget.size / (_barCount * 2);
    final gap = barWidth * 0.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              return Container(
                width: barWidth,
                height: widget.size * _animations[i].value,
                margin: EdgeInsets.only(right: i < _barCount - 1 ? gap : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
