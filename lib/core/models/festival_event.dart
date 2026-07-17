import 'package:flutter/material.dart';

class FestivalEvent {
  const FestivalEvent({
    required this.name,
    required this.date,
    required this.tagline,
    required this.playlistTitle,
    required this.palette,
  });

  final String name;
  final DateTime date;
  final String tagline;
  final String playlistTitle;
  final List<Color> palette;
}
