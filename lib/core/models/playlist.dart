import 'package:flutter/material.dart';

import 'song.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.songs,
    required this.curator,
    required this.gradient,
    this.members = const <String>[],
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Song> songs;
  final String curator;
  final List<Color> gradient;
  final List<String> members;

  Playlist copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<Song>? songs,
    String? curator,
    List<Color>? gradient,
    List<String>? members,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      songs: songs ?? this.songs,
      curator: curator ?? this.curator,
      gradient: gradient ?? this.gradient,
      members: members ?? this.members,
    );
  }
}
