import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_details_controller.dart';
import 'package:flutter/material.dart';

class ProjectDetailsPage extends AgBasePage<ProjectDetailsController> {
  const ProjectDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
    title: const Text('Project'),
    actions: [
      IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        tooltip: 'Delete project',
        onPressed: controller.delete,
      ),
    ],
  );

  @override
  Widget buildSuccess(BuildContext context) {
    final project = controller.state.dataOrNull!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(project.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('View tasks for this project'),
              onPressed: () => RouteManagement.goToProjectTasksPage(
                ProjectTasksPageArgument(projectId: project.id),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
