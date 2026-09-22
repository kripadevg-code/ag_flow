// ignore_for_file: dangling_library_doc_comments
// Navigation arguments for every detail / nested route.
///
/// Each class:
///   • holds the typed ID passed from the list page
///   • has a [fromPathParameters] factory so the page opens correctly
///     from a deep link (cold start, push notification, browser reload)
///   • has [toPathParameters] so [RouteManagement] never builds URL
///     strings by hand

class TaskDetailsPageArgument {
  const TaskDetailsPageArgument({required this.taskId});

  factory TaskDetailsPageArgument.fromPathParameters(
    Map<String, String> params,
  ) {
    final id = int.tryParse(params['id'] ?? '');
    if (id == null) throw ArgumentError('Invalid task id: ${params['id']}');
    return TaskDetailsPageArgument(taskId: id);
  }

  final int taskId;

  Map<String, String> toPathParameters() => {'id': '$taskId'};
}

class ProjectDetailsPageArgument {
  const ProjectDetailsPageArgument({required this.projectId});

  factory ProjectDetailsPageArgument.fromPathParameters(
    Map<String, String> params,
  ) {
    final id = int.tryParse(params['id'] ?? '');
    if (id == null) {
      throw ArgumentError('Invalid project id: ${params["id"]}');
    }
    return ProjectDetailsPageArgument(projectId: id);
  }

  final int projectId;

  Map<String, String> toPathParameters() => {'id': '$projectId'};
}

class ProjectTasksPageArgument {
  const ProjectTasksPageArgument({required this.projectId});

  factory ProjectTasksPageArgument.fromPathParameters(
    Map<String, String> params,
  ) {
    final id = int.tryParse(params['id'] ?? '');
    if (id == null) {
      throw ArgumentError('Invalid project id: ${params["id"]}');
    }
    return ProjectTasksPageArgument(projectId: id);
  }

  final int projectId;

  Map<String, String> toPathParameters() => {'id': '$projectId'};
}
