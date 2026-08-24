import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/routes/route_management.dart';
import 'package:ag_showcase_blog/modules/post/components/details/post_details_appbar.dart';
import 'package:ag_showcase_blog/modules/post/components/details/post_details_empty.dart';
import 'package:ag_showcase_blog/modules/post/components/details/post_details_error.dart';
import 'package:ag_showcase_blog/modules/post/components/details/post_details_loading.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_controller.dart';
import 'package:flutter/material.dart';

class PostDetailsPage extends AgBasePage<PostDetailsController> {
  const PostDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => PostDetailsAppBar(
    onEdit: () => _showEditDialog(context),
    onDelete: () => controller.delete(),
  );

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const PostDetailsLoading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          PostDetailsError(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const PostDetailsEmpty();

  @override
  Widget buildSuccess(BuildContext context) {
    final data = controller.state.dataOrNull!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'by user ${data.userId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(data.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => RouteManagement.goToPostDetailsCommentsPage(
              PostDetailsCommentsPageArgument(postId: data.id),
            ),
            child: const Text('View Comments'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final data = controller.state.dataOrNull;
    if (data == null) return;

    final titleController = TextEditingController(text: data.title);
    final bodyController = TextEditingController(text: data.body);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.update(
                  data.copyWith(
                    title: titleController.text,
                    body: bodyController.text,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
