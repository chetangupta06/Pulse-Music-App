import 'package:flutter/material.dart';

class LyricLine {
  const LyricLine({required this.time, required this.text, this.translation});

  final Duration time;
  final String text;
  final String? translation;
}

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.language,
    required this.genre,
    required this.mood,
    required this.duration,
    required this.palette,
    required this.lyrics,
    this.bitrateLabel = '320 kbps',
    this.downloaded = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String language;
  final String genre;
  final String mood;
  final Duration duration;
  final List<Color> palette;
  final List<LyricLine> lyrics;
  final String bitrateLabel;
  final bool downloaded;
}
