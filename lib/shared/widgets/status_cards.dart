import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import 'desi_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DesiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadSummaryCard extends StatelessWidget {
  const DownloadSummaryCard({
    super.key,
    required this.completed,
    required this.queued,
  });

  final int completed;
  final int queued;

  @override
  Widget build(BuildContext context) {
    return DesiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Offline Strength',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '${compactNumber(completed)} ready - ${compactNumber(queued)} warming',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: queued == 0 ? 1 : completed / (completed + queued),
          ),
        ],
      ),
    );
  }
}
