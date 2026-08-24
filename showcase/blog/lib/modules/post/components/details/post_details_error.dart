import 'package:flutter/material.dart';

/// The error state for the PostDetails page.
/// Generated as a starting point — customize freely, or delete this file
/// and its use in the page to fall back to AG's default error widget.
class PostDetailsError extends StatelessWidget {
  const PostDetailsError({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
