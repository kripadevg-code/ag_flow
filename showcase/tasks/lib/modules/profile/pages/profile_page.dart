import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';

/// Profile screen — uses [AgBuilder] directly rather than [AgBasePage]
/// because there is no async loading state (data is synchronous from
/// [AuthService]).
///
/// Demonstrates [AgBuilder] as a lightweight listener when you need
/// reactive rebuilds without the full AgBasePage loading/error machinery.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.find;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AgBuilder(
        listenable: controller,
        builder: (context) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar ───────────────────────────────────────────────
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    controller.displayName.isNotEmpty
                        ? controller.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  controller.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'User ID: ${controller.userId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),

              // ── Architecture note ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AG Flow Architecture Notes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• This screen uses AgBuilder directly — no async load.\n'
                      '• ProfileController reads from AuthService.instance (no generics).\n'
                      '• Sign out → AuthService.logout() → guard redirects to /login.\n'
                      '• Shell stays alive across all three tabs (AgShellRoute).',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Sign out ──────────────────────────────────────────────
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                onPressed: controller.signOut,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor:
                      Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
