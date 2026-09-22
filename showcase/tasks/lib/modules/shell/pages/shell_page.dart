import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

/// The persistent shell that wraps all authenticated tabs.
///
/// This widget is kept alive as the user navigates between tabs — it is
/// never rebuilt when switching from Tasks to Projects to Profile and back.
/// That is [AgShellRoute]'s whole purpose: the bottom nav bar, its selected
/// index, and any shell-level state all survive every tab switch.
///
/// Navigation calls use [AgNavigator.offAllNamed] so the selected tab
/// becomes the app's current location (address-bar-friendly on the web).
class ShellPage extends StatelessWidget {
  const ShellPage({required this.child, super.key});

  /// The currently-active tab's page widget, rendered by go_router.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = AgNavigator.location;
    final selectedIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onTap(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_box_outline_blank_rounded),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _indexFor(String location) {
    if (location.startsWith(AppRoutes.projects)) return 1;
    if (location.startsWith(AppRoutes.profile)) return 2;
    return 0; // tasks (default)
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        AgNavigator.offAllNamed(AppRoutes.tasks);
      case 1:
        AgNavigator.offAllNamed(AppRoutes.projects);
      case 2:
        AgNavigator.offAllNamed(AppRoutes.profile);
    }
  }
}
