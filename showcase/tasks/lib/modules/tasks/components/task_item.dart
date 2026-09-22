import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  const TaskItem({
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconButton(
        icon: Icon(
          task.completed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: task.completed
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        onPressed: onToggle,
        tooltip: task.completed ? 'Mark incomplete' : 'Mark complete',
      ),
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: task.completed ? Theme.of(context).colorScheme.outline : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
    );
  }
}
