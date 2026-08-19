import 'package:flutter/material.dart';

/// AG's default loading indicator.
///
/// Feature-independent by design — contains no business logic and no
/// knowledge of what is loading, so it stays reusable across every module.
class AgLoading extends StatelessWidget {
  const AgLoading({super.key, this.message});

  /// Optional message shown below the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
