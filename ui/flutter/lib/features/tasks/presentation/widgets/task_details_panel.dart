import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../api/model/task_stats.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/app_palette.dart';
import '../../application/task_stats_provider.dart';
import '../../domain/task_record.dart';
import 'task_card/task_card_parts.dart';

/// Compact summary of the selected task, docked under the task list.
class TaskDetailsPanel extends ConsumerWidget {
  const TaskDetailsPanel({super.key, required this.task, required this.onOpenDetails, required this.onClose});

  final TaskRecord task;
  final VoidCallback onOpenDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = context.l10n;
    final stats = ref.watch(taskStatsProvider((taskId: task.id, protocol: task.protocol))).value;
    final connections = stats is HttpTaskStats ? stats.connections : const <HttpConnectionStats>[];

    final metaStyle = TextStyle(color: palette.taskMeta, fontSize: 11.5, height: 1);
    final statusText = switch (task.status) {
      TaskStatus.downloading => l10n.downloading,
      TaskStatus.paused => l10n.pause,
      TaskStatus.completed => l10n.completed,
      TaskStatus.failed => l10n.failed,
    };
    final doneText = task.total == null ? task.downloaded : '${task.downloaded} / ${task.total}';

    return Container(
      key: const ValueKey('task-details-panel'),
      decoration: BoxDecoration(
        color: palette.sideBg,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  task.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle.copyWith(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    Text(statusText, style: metaStyle),
                    Text(doneText, style: metaStyle),
                    if (connections.isNotEmpty) Text(l10n.connectionCount(connections.length), style: metaStyle),
                    Text(task.storagePath, maxLines: 1, overflow: TextOverflow.ellipsis, style: metaStyle),
                  ],
                ),
              ],
            ),
          ),
          if (connections.isNotEmpty) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.connectionStatus.toUpperCase(),
                    style: TextStyle(color: palette.textMuted, fontSize: 10.5, letterSpacing: 0.6, height: 1),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        for (var i = 0; i < connections.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(child: _ConnectionSegment(connection: connections[i])),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 12),
          TaskCardActionButton(
            icon: Icons.open_in_full,
            color: palette.taskCardAction,
            onPressed: onOpenDetails,
            hoverBackground: palette.cardHoverBg,
            buttonSize: 22,
          ),
          TaskCardActionButton(
            icon: Icons.close,
            color: palette.taskCardAction,
            onPressed: onClose,
            hoverBackground: palette.cardHoverBg,
            buttonSize: 22,
          ),
        ],
      ),
    );
  }
}

class _ConnectionSegment extends StatelessWidget {
  const _ConnectionSegment({required this.connection});

  final HttpConnectionStats connection;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final value = connection.completed
        ? 1.0
        : connection.total > 0
        ? (connection.downloaded / connection.total).clamp(0.0, 1.0)
        : 0.0;
    final color = connection.failed ? palette.error : palette.brandProgress;
    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: ColoredBox(
        color: palette.brandTrack,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}
