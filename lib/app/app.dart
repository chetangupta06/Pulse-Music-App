import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/app_shell.dart';

class PULSEApp extends ConsumerWidget {
  const PULSEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePack = ref.watch(themePackProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PULSE',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.build(themePack: themePack, brightness: Brightness.light),
      darkTheme: AppTheme.build(
        themePack: themePack,
        brightness: Brightness.dark,
      ),
      home: const AppShell(),
    );
  }
}
