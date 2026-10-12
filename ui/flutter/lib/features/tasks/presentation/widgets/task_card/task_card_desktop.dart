import 'package:flutter/gestures.dart' show TapUpDetails, kDoubleTapSlop, kDoubleTapTimeout;
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../../../core/window/app_window_chrome.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/app_design_tokens.dart';
import '../../../../../shared/theme/app_palette.dart';
import '../../../domain/task_record.dart';
import '../../task_record_localizations.dart';
import '../task_progress_bar.dart';
import 'task_card_parts.dart';

class TaskCardDesktop extends StatefulWidget {
  const TaskCardDesktop({
    super.key,
    required this.task,
    required this.selected,
    required this.batchMode,
    required this.selectedInBatch,
    required this.onPressed,
    required this.onToggleBatch,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.onOpen,
    this.onReveal,
    this.listeningForUpdate = false,
  });

  final TaskRecord task;
  final bool selected;
  final bool batchMode;
  final bool selectedInBatch;
  final VoidCallback onPressed;
  final VoidCallback onToggleBatch;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;
  final VoidCallback? onReveal;
  final bool listeningForUpdate;

  @override
  State<TaskCardDesktop> createState() => _TaskCardDesktopState();
}

class _TaskCardDesktopState extends State<TaskCardDesktop> {
  bool _hovered = false;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  void _handleTap(TapUpDetails details) {
    final now = DateTime.now();
    final lastTapTime = _lastTapTime;
    final lastTapPosition = _lastTapPosition;
    final isDoubleTap =
        !widget.batchMode &&
        widget.task.status == TaskStatus.completed &&
        lastTapTime != null &&
        now.difference(lastTapTime) <= kDoubleTapTimeout &&
        lastTapPosition != null &&
        (details.globalPosition - lastTapPosition).distance <= kDoubleTapSlop;

    _lastTapTime = isDoubleTap ? null : now;
    _lastTapPosition = isDoubleTap ? null : details.globalPosition;
    widget.onPressed();
    if (isDoubleTap) {
      widget.onOpen?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final task = widget.task;
    final isDark = shad.Theme.of(context).brightness == Brightness.dark;
    final isError = task.status == TaskStatus.failed;
    final l10n = context.l10n;
    final showHover = _hovered && !widget.selected;
    final rowColor = widget.selected
        ? palette.itemActiveBg
        : showHover
        ? palette.taskCardHoverBg
        : Colors.transparent;
    final fillColor = taskCardFillColor(palette, task.status, isDark);
    final metaStyle = TextStyle(color: palette.taskMeta, fontSize: 11.5, height: 1, fontFeatures: _tabular);
    final textStyle = TextStyle(color: palette.textPrimary, fontSize: 12.5, height: 1, fontFeatures: _tabular);

    final etaText = switch (task.status) {
      TaskStatus.downloading || TaskStatus.paused => task.localizedRemaining(l10n) ?? '—',
      TaskStatus.completed => l10n.completed,
      TaskStatus.failed => l10n.failed,
    };
    final sizeText = switch (task.status) {
      TaskStatus.completed => task.total ?? task.downloaded,
      _ when task.total != null => '${task.downloaded} / ${task.total}',
      _ when task.downloadedBytes == 0 => l10n.unknownSize,
      _ => task.downloaded,
    };
    final progress = task.status == TaskStatus.completed ? 1.0 : task.progress;
    final pctText = progress == null ? '—' : '${(progress * 100).floor()}%';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTap,
        child: DecoratedBox(
          key: const ValueKey('task-card-row'),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border.withValues(alpha: 0.5))),
          ),
          child: ColoredBox(
            key: showHover ? const ValueKey('task-card-hover-surface') : null,
            color: rowColor,
            child: SizedBox(
              height: AppDesignTokens.taskRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: widget.batchMode ? 32 : 0,
                      child: widget.batchMode
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: shad.Checkbox(
                                state: widget.selectedInBatch
                                    ? shad.CheckboxState.checked
                                    : shad.CheckboxState.unchecked,
                                onChanged: (_) => widget.onToggleBatch(),
                                borderColor: palette.border,
                                backgroundColor: palette.cardBg,
                                size: 16,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    TaskCardIcon(task: task, size: 22, iconSize: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isError ? palette.error : palette.textPrimary,
                              ),
                            ),
                          ),
                          if (widget.listeningForUpdate) ...[
                            const SizedBox(width: 8),
                            const TaskUpdateListeningIndicator(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: TaskListColumns.progress,
                      child: Row(
                        children: [
                          Expanded(
                            child: TaskProgressBar(
                              value: progress,
                              indeterminate: task.isIndeterminate,
                              trackColor: palette.brandTrack,
                              fillColor: fillColor,
                              highlightStartColor: fillColor,
                              highlightEndColor: fillColor,
                              shimmer: task.status == TaskStatus.downloading && !task.waiting,
                              height: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(pctText, textAlign: TextAlign.right, style: metaStyle),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: TaskListColumns.size,
                      child: Text(
                        sizeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: metaStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: TaskListColumns.speed,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.uploading) ...[
                                _SpeedValue(icon: Icons.north, value: task.uploadSpeed!, style: textStyle),
                                const SizedBox(width: 6),
                              ],
                              if (task.speed != null)
                                _SpeedValue(icon: Icons.south, value: task.speed!, style: textStyle),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: TaskListColumns.eta,
                      child: Text(
                        etaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: isError ? metaStyle.copyWith(color: palette.error) : metaStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: TaskListColumns.actions,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: _buildActionButtons(task, palette, isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(TaskRecord task, AppPalette palette, bool isDark) {
    final actions = switch (task.status) {
      TaskStatus.downloading => [(Icons.pause, widget.onPause), (Icons.close, widget.onDelete)],
      TaskStatus.paused => [(Icons.play_arrow, widget.onResume), (Icons.close, widget.onDelete)],
      TaskStatus.failed => [(Icons.refresh, widget.onResume), (Icons.delete_outline, widget.onDelete)],
      TaskStatus.completed => [
        if (AppWindowChrome.isDesktopWindow) (Icons.folder_open_outlined, widget.onReveal),
        (Icons.delete_outline, widget.onDelete),
      ],
    };

    return actions
        .map(
          (action) => TaskCardActionButton(
            icon: action.$1,
            color: palette.taskCardAction,
            onPressed: action.$2 ?? () {},
            hoverBackground: isDark ? palette.border : palette.cardHoverBg,
            buttonSize: 22,
            iconSize: 14,
          ),
        )
        .toList(growable: false);
  }
}

const _tabular = [FontFeature.tabularFigures()];

/// Fixed column widths shared by the task list header and the rows.
abstract final class TaskListColumns {
  static const double progress = 150;
  static const double size = 132;
  static const double speed = 96;
  static const double eta = 84;
  static const double actions = 52;
}

/// Column titles matching [TaskCardDesktop] rows (compact table layout).
class TaskListHeader extends StatelessWidget {
  const TaskListHeader({super.key, this.leading = 0});

  /// Extra leading space reserved for the batch-selection checkbox column.
  final double leading;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = context.l10n;
    final style = TextStyle(color: palette.textMuted, fontSize: 11, height: 1);
    Widget cell(String text, double width, {TextAlign align = TextAlign.right}) => SizedBox(
      width: width,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: align, style: style),
    );

    return Container(
      key: const ValueKey('task-list-header'),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: leading + 22 + 12),
          Expanded(
            child: Text(l10n.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
          const SizedBox(width: 12),
          cell(l10n.progress, TaskListColumns.progress, align: TextAlign.left),
          const SizedBox(width: 12),
          cell(l10n.size, TaskListColumns.size),
          const SizedBox(width: 12),
          cell(l10n.speed, TaskListColumns.speed),
          const SizedBox(width: 12),
          cell(l10n.remaining, TaskListColumns.eta),
          const SizedBox(width: 12),
          const SizedBox(width: TaskListColumns.actions),
        ],
      ),
    );
  }
}

class _SpeedValue extends StatelessWidget {
  const _SpeedValue({required this.icon, required this.value, required this.style});

  final IconData icon;
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: style.color),
        const SizedBox(width: 2),
        Text(value, maxLines: 1, style: style),
      ],
    );
  }
}
