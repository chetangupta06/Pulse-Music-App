import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final BoxDecoration? hoverDecoration;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Duration duration;
  final double? hoverScale;
  final VoidCallback? onTap;

  const HoverContainer({
    super.key,
    required this.child,
    this.decoration,
    this.hoverDecoration,
    this.padding,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
    this.hoverScale,
    this.onTap,
  });

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.duration,
          padding: widget.padding,
          decoration: (_isHovering ? widget.hoverDecoration : widget.decoration)?.copyWith(
            borderRadius: widget.borderRadius,
          ) ?? BoxDecoration(borderRadius: widget.borderRadius),
          transform: (widget.hoverScale != null && _isHovering)
              ? (Matrix4.identity()..scale(widget.hoverScale!))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
