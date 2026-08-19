import 'package:flutter/material.dart';

/// AG's default empty-state display.
///
/// Feature-independent by design — contains no business logic and no
/// knowledge of what's empty, so it stays reusable across every module.
class AgEmpty extends StatelessWidget {
  const AgEmpty({super.key, this.message, this.icon, this.action});

  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message ?? 'Nothing here yet', textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
