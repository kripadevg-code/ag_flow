import 'package:ag_flow/src/repo/ag_repo_exception.dart';
import 'package:flutter/material.dart';

/// AG's default error display.
///
/// Feature-independent by design — contains no business logic and no
/// knowledge of what failed, so it stays reusable across every module.
class AgError extends StatelessWidget {
  const AgError({
    required this.error,
    super.key,
    this.stackTrace,
    this.onRetry,
    this.message,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  /// Text to show. Defaults to [AgRepoException.message] for a Repo
  /// failure, otherwise `error.toString()`.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              message ??
                  switch (error) {
                    final AgRepoException e => e.message,
                    _ => error.toString(),
                  },
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
