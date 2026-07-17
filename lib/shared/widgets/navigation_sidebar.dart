import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';

class NavigationSidebar extends ConsumerWidget {
  const NavigationSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(currentDestinationProvider);
    final theme = Theme.of(context);

    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.52),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'PULSE',
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Indian music, guest-mode only, desktop first',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: AppDestination.values.map((AppDestination destination) {
                final isActive = selected == destination;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      backgroundColor: isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.16)
                          : theme.colorScheme.surface.withValues(alpha: 0.4),
                      foregroundColor: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    onPressed: () => ref
                        .read(currentDestinationProvider.notifier)
                        .state = destination,
                    icon: Icon(destination.icon),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(destination.label),
                        Text(
                          destination.shortcutLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Guest Mode', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'No ads. No account. Local-first comfort.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
