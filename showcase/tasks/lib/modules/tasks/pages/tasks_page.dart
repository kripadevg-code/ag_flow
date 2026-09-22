import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/modules/tasks/components/task_item.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/tasks_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:flutter/material.dart';

class TasksPage extends AgBasePage<TasksController> {
  const TasksPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
    title: const Text('My Tasks'),
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'New task',
        onPressed: () => _showAddDialog(context),
      ),
    ],
  );

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Task, int>(
      controller: controller,
      itemBuilder: (context, task, index) => TaskItem(
        task: task,
        onTap: () => RouteManagement.goToTaskDetailsPage(
          TaskDetailsPageArgument(taskId: task.id),
        ),
        onToggle: () => controller.toggleCompleted(task),
        onDelete: () => controller.delete(task.id),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New task'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Task title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addTask(ctx, textController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _addTask(ctx, textController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext ctx, String title) {
    if (title.trim().isEmpty) return;
    controller.add(Task(id: 0, userId: 1, title: title.trim(), completed: false));
    Navigator.of(ctx).pop();
  }
}
