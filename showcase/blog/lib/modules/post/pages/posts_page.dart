import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/arguments/arguments.dart';
import 'package:ag_showcase_blog/core/routes/route_management.dart';
import 'package:ag_showcase_blog/modules/post/components/post/post_appbar.dart';
import 'package:ag_showcase_blog/modules/post/components/post/post_empty.dart';
import 'package:ag_showcase_blog/modules/post/components/post/post_error.dart';
import 'package:ag_showcase_blog/modules/post/components/post/post_item.dart';
import 'package:ag_showcase_blog/modules/post/components/post/post_loading.dart';
import 'package:ag_showcase_blog/modules/post/controllers/posts_controller.dart';
import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:flutter/material.dart';

class PostsPage extends AgBasePage<PostsController> {
  const PostsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => PostAppBar();

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const PostLoading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          PostError(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const PostEmpty();

  @override
  Widget? floatingActionButton(BuildContext context) => FloatingActionButton(
    onPressed: () => _showAddPostDialog(context),
    tooltip: 'New post',
    child: const Icon(Icons.add),
  );

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Post, int>(
      controller: controller,
      itemBuilder: (context, item, index) => PostItem(
        item: item,
        onTap: () => RouteManagement.goToPostDetailsPage(
          PostDetailsPageArgument(postId: item.id),
        ),
        onDelete: () => controller.delete(item.id),
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New post'),
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
                controller.add(
                  Post(
                    id: 0,
                    userId: 1,
                    title: titleController.text,
                    body: bodyController.text,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
