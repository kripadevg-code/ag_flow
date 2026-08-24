import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/components/comments/post_details_comments_appbar.dart';
import 'package:ag_showcase_blog/modules/post/components/comments/post_details_comments_empty.dart';
import 'package:ag_showcase_blog/modules/post/components/comments/post_details_comments_error.dart';
import 'package:ag_showcase_blog/modules/post/components/comments/post_details_comments_loading.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_comments_controller.dart';
import 'package:flutter/material.dart';

class PostDetailsCommentsPage
    extends AgBasePage<PostDetailsCommentsController> {
  const PostDetailsCommentsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      PostDetailsCommentsAppBar();

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const PostDetailsCommentsLoading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          PostDetailsCommentsError(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const PostDetailsCommentsEmpty();

  @override
  Widget buildSuccess(BuildContext context) {
    final comments = controller.state.dataOrNull!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                comment.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 6),
              Text(comment.body),
            ],
          ),
        );
      },
    );
  }
}
