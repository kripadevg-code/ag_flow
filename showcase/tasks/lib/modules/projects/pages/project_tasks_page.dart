import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_tasks_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/components/task_item.dart';
import 'package:flutter/material.dart';

/// Nested tasks page — the detail-shaped module whose data is a list.
///
/// Demonstrates using [AgDetailController] as the base for a collection
/// filtered by a parent argument, rather than a standalone paginated list.
class ProjectTasksPage extends AgBasePage<ProjectTasksController> {
  const ProjectTasksPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      AppBar(title: const Text('Project tasks'));

  @override
  Widget buildSuccess(BuildContext context) {
    final tasks = controller.state.dataOrNull ?? [];
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks for this project.'));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          task: task,
          onTap: () => RouteManagement.goToTaskDetailsPage(
            TaskDetailsPageArgument(taskId: task.id),
          ),
          onToggle: () {},
          onDelete: () {},
        );
      },
    );
  }
}
