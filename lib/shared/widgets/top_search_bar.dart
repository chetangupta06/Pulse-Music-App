import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class TopSearchBar extends ConsumerWidget {
  const TopSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final festivalMode = ref.watch(festivalModeProvider);
    final themePack = ref.watch(themePackProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            initialValue: searchQuery,
            onChanged: (String value) =>
                ref.read(searchQueryProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText:
                  'Search Bollywood, bhakti, regional gems, or type a mood',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () => _openVoiceCommandDialog(context, ref),
                icon: const Icon(Icons.mic_rounded),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            borderRadius: BorderRadius.circular(20),
            items: supportedLanguages
                .map(
                  (String item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (String? value) {
              if (value != null) {
                ref.read(selectedLanguageProvider.notifier).state = value;
              }
            },
          ),
        ),
        const SizedBox(width: 14),
        FilterChip(
          selected: festivalMode,
          onSelected: (bool value) =>
              ref.read(festivalModeProvider.notifier).state = value,
          label: const Text('Festival Mode'),
          avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
        ),
        const SizedBox(width: 14),
        DropdownButtonHideUnderline(
          child: DropdownButton<FestivalThemePack>(
            value: themePack,
            borderRadius: BorderRadius.circular(20),
            items: AppTheme.packs
                .map(
                  (FestivalThemePack pack) =>
                      DropdownMenuItem<FestivalThemePack>(
                    value: pack,
                    child: Text(pack.name),
                  ),
                )
                .toList(),
            onChanged: (FestivalThemePack? value) {
              if (value != null) {
                ref.read(themePackProvider.notifier).state = value;
              }
            },
          ),
        ),
        const SizedBox(width: 14),
        IconButton.filledTonal(
          onPressed: () {
            ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
        ),
      ],
    );
  }

  Future<void> _openVoiceCommandDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController(
      text: 'PULSE, play latest Arijit sad songs',
    );
    final command = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Voice Command'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type the voice command transcript',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Run'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || command == null || command.trim().isEmpty) {
      return;
    }

    final message =
        ref.read(playbackControllerProvider).handleVoiceCommand(command);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
