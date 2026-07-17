import 'package:flutter/material.dart';

class Station {
  const Station({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.listeners,
    required this.palette,
    this.votes = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final int listeners;
  final List<Color> palette;
  final int votes;

  Station copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    int? listeners,
    List<Color>? palette,
    int? votes,
  }) {
    return Station(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      listeners: listeners ?? this.listeners,
      palette: palette ?? this.palette,
      votes: votes ?? this.votes,
    );
  }
}
