import 'dart:ui';

import 'package:flutter/material.dart';

class DesiCard extends StatefulWidget {
  const DesiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.gradient,
    this.borderRadius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double borderRadius;

  @override
  State<DesiCard> createState() => _DesiCardState();
}

class _DesiCardState extends State<DesiCard> {
  bool _hovered = false;
  bool? _queuedHover;

  void _scheduleHover(bool value) {
    if (_hovered == value || _queuedHover == value) {
      return;
    }

    _queuedHover = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _queuedHover == null) {
        return;
      }

      final nextHover = _queuedHover!;
      _queuedHover = null;

      if (_hovered == nextHover) {
        return;
      }

      setState(() => _hovered = nextHover);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor:
          widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => _scheduleHover(true),
      onExit: (_) => _scheduleHover(false),
      child: AnimatedScale(
        scale: _hovered ? 1.01 : 1,
        duration: const Duration(milliseconds: 180),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    color: widget.gradient == null
                        ? theme.colorScheme.surface.withValues(
                            alpha: _hovered ? 0.88 : 0.72,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(
                        alpha: _hovered ? 0.9 : 0.45,
                      ),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        blurRadius: _hovered ? 36 : 22,
                        offset: const Offset(0, 18),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
