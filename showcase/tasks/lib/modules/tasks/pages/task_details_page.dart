import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/task_details_controller.dart';
import 'package:flutter/material.dart';

class TaskDetailsPage extends AgBasePage<TaskDetailsController> {
  const TaskDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
    title: const Text('Task detail'),
  );

  @override
  Widget buildSuccess(BuildContext context) {
    final task = controller.state.dataOrNull!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status chip ─────────────────────────────────────────────
          Row(
            children: [
              FilterChip(
                label: Text(task.completed ? 'Completed' : 'In progress'),
                selected: task.completed,
                onSelected: (_) => controller.toggleCompleted(),
                avatar: Icon(
                  task.completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Title ────────────────────────────────────────────────────
          Text('Title', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 1.2,
          )),
          const SizedBox(height: 4),
          Text(task.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),

          // ── Metadata ─────────────────────────────────────────────────
          _MetaTile(
            icon: Icons.person_outline,
            label: 'Assigned to',
            value: 'User ${task.userId}',
          ),
          const SizedBox(height: 8),
          _MetaTile(
            icon: Icons.tag,
            label: 'Task ID',
            value: '#${task.id}',
          ),
          const Spacer(),

          // ── Toggle button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: Icon(
                task.completed ? Icons.undo_rounded : Icons.done_rounded,
              ),
              label: Text(
                task.completed ? 'Mark as in progress' : 'Mark as completed',
              ),
              onPressed: controller.toggleCompleted,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }
}
