import 'package:flutter/material.dart';

/// The app bar for the PostDetails page — an edit action (opens a dialog
/// pre-filled with the current title/body) and a delete action.
class PostDetailsAppBar extends AppBar {
  PostDetailsAppBar({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    super.key,
  }) : super(
         title: const Text('Post'),
         actions: [
           IconButton(
             icon: const Icon(Icons.edit_outlined),
             tooltip: 'Edit',
             onPressed: onEdit,
           ),
           IconButton(
             icon: const Icon(Icons.delete_outline),
             tooltip: 'Delete',
             onPressed: onDelete,
           ),
         ],
       );
}
