import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/modules/projects/components/project_item.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/projects_controller.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:flutter/material.dart';

class ProjectsPage extends AgBasePage<ProjectsController> {
  const ProjectsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => AppBar(
    title: const Text('Projects'),
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'New project',
        onPressed: () => _showAddDialog(context),
      ),
    ],
  );

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Project, int>(
      controller: controller,
      itemBuilder: (context, project, index) => ProjectItem(
        project: project,
        onTap: () => RouteManagement.goToProjectDetailsPage(
          ProjectDetailsPageArgument(projectId: project.id),
        ),
        onDelete: () => controller.delete(project.id),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              controller.add(
                Project(
                  id: 0,
                  userId: 1,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
