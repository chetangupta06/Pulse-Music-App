import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/song.dart';
import '../../core/providers/app_providers.dart';
import '../../utils/formatters.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    final currentSong = playback.currentSong;
    final totalDuration = playback.totalDuration;

    return Container(
      height: 194,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: currentSong == null
          ? const Center(child: Text('Choose a station or song to begin.'))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PlayerArt(song: currentSong),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${currentSong.artist} - ${currentSong.album}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Chip(label: Text(currentSong.bitrateLabel)),
                          const SizedBox(width: 8),
                          Chip(label: Text(playback.audioSourceLabel)),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () => ref
                                .read(downloadManagerProvider)
                                .queueSong(currentSong),
                            icon: const Icon(
                              Icons.download_for_offline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: playback.position.inMilliseconds
                            .clamp(
                                0,
                                totalDuration.inMilliseconds <= 0
                                    ? 1
                                    : totalDuration.inMilliseconds)
                            .toDouble(),
                        max: totalDuration.inMilliseconds <= 0
                            ? 1
                            : totalDuration.inMilliseconds.toDouble(),
                        onChanged: (double value) {
                          ref.read(playbackControllerProvider).seek(
                                Duration(milliseconds: value.round()),
                              );
                        },
                      ),
                      Row(
                        children: <Widget>[
                          Text(formatDuration(playback.position)),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                ref.read(playbackControllerProvider).previous(),
                            icon: const Icon(Icons.skip_previous_rounded),
                          ),
                          IconButton.filled(
                            onPressed: () => ref
                                .read(playbackControllerProvider)
                                .togglePlayPause(),
                            icon: Icon(
                              playback.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                ref.read(playbackControllerProvider).next(),
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                          const Spacer(),
                          Text(formatDuration(totalDuration)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          _CompactToggleChip(
                            label: 'Spatial',
                            selected: playback.spatialAudioEnabled,
                            onSelected: () => ref
                                .read(playbackControllerProvider)
                                .toggleSpatialAudio(),
                          ),
                          _CompactToggleChip(
                            label: 'Radio',
                            selected: playback.radioModeEnabled,
                            onSelected: () => ref
                                .read(playbackControllerProvider)
                                .toggleRadioMode(),
                          ),
                          _CompactToggleChip(
                            label: 'Karaoke',
                            selected: playback.karaokeModeEnabled,
                            onSelected: () => ref
                                .read(playbackControllerProvider)
                                .toggleKaraokeMode(),
                          ),
                          _CompactToggleChip(
                            label: 'Skip Silence',
                            selected: playback.skipSilenceEnabled,
                            onSelected: () => ref
                                .read(playbackControllerProvider)
                                .toggleSkipSilence(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: playback.equalizerPreset,
                                isExpanded: true,
                                items: equalizerPresets
                                    .map(
                                      (String preset) =>
                                          DropdownMenuItem<String>(
                                        value: preset,
                                        child: Text(
                                          preset,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    ref
                                        .read(playbackControllerProvider)
                                        .setEqualizerPreset(value);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            tooltip: 'Sleep timer',
                            onSelected: (String value) {
                              final controller = ref.read(
                                playbackControllerProvider,
                              );
                              if (value == 'off') {
                                controller.setSleepTimer(null);
                              } else if (value == '5') {
                                controller.setSleepTimer(
                                  const Duration(minutes: 5),
                                );
                              } else if (value == '15') {
                                controller.setSleepTimer(
                                  const Duration(minutes: 15),
                                );
                              } else if (value == '30') {
                                controller.setSleepTimer(
                                  const Duration(minutes: 30),
                                );
                              } else if (value == '60') {
                                controller.setSleepTimer(
                                  const Duration(minutes: 60),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'off',
                                child: Text('Sleep timer off'),
                              ),
                              PopupMenuItem<String>(
                                value: '5',
                                child: Text('5 minutes'),
                              ),
                              PopupMenuItem<String>(
                                value: '15',
                                child: Text('15 minutes'),
                              ),
                              PopupMenuItem<String>(
                                value: '30',
                                child: Text('30 minutes'),
                              ),
                              PopupMenuItem<String>(
                                value: '60',
                                child: Text('60 minutes'),
                              ),
                            ],
                            child: const Chip(label: Text('Sleep Timer')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crossfade ${playback.crossfadeSeconds.toStringAsFixed(0)}s',
                      ),
                      Slider(
                        value: playback.crossfadeSeconds,
                        min: 0,
                        max: 10,
                        onChanged: (double value) {
                          ref
                              .read(playbackControllerProvider)
                              .setCrossfade(value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CompactToggleChip extends StatelessWidget {
  const _CompactToggleChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(label),
      onSelected: (_) => onSelected(),
    );
  }
}

class _PlayerArt extends StatelessWidget {
  const _PlayerArt({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: song.palette),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
