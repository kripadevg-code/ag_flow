import 'package:ag_showcase_blog/modules/post/models/post.dart';
import 'package:flutter/material.dart';

/// A reusable item widget for the Post collection: a card with the post's
/// title/body preview, a delete action, and a tap target that navigates to
/// the post's details.
class PostItem extends StatelessWidget {
  const PostItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Post item;

  /// Navigates to this post's details page.
  final VoidCallback onTap;

  /// Deletes this post.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
