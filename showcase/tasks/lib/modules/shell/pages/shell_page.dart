import 'package:ag_showcase_tasks/core/routes/app_routes.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:flutter/material.dart';

/// The persistent shell that wraps all authenticated tabs.
///
/// This widget is kept alive as the user navigates between tabs — it is
/// never rebuilt when switching from Tasks to Projects to Profile and back.
/// That is go_router's `ShellRoute`'s whole purpose: the bottom nav bar,
/// its selected index, and any shell-level state all survive every tab
/// switch.
///
/// Tab switches call `RouteManagement.goToXPage()`, which uses `goNamed`
/// so the selected tab becomes the app's current location
/// (address-bar-friendly on the web).
class ShellPage extends StatelessWidget {
  const ShellPage({required this.location, required this.child, super.key});

  /// The shell's current location (`GoRouterState.uri.path`), handed in
  /// by the `ShellRoute` builder — it decides which tab is selected.
  final String location;

  /// The currently-active tab's page widget, rendered by go_router.
  final Widget child;

  @override
  Widget build(BuildContext context) {
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

  static int _indexFor(String path) {
    if (path.startsWith(AppRoutes.projects)) return 1;
    if (path.startsWith(AppRoutes.profile)) return 2;
    return 0; // tasks (default)
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        RouteManagement.goToTasksPage();
      case 1:
        RouteManagement.goToProjectsPage();
      case 2:
        RouteManagement.goToProfilePage();
    }
  }
}
