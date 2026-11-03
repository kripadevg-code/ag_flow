import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';

/// Local copy of the tasks the app last saw, used when the network is down.
///
/// Only the Repos use it: they save what the Service returns and read it
/// back on a network error. It lives for the whole app run (registered in
/// `InitialBinding`), so a page opened again offline still has data.
///
/// This showcase keeps it in memory. A real app keeps the same methods and
/// writes to disk (sqflite, drift, hive, shared_preferences, ...).
class TasksStore {
  final _pages = <int, List<Task>>{};
  final _byId = <int, Task>{};

  /// The tasks saved for list [page], or null if that page was never loaded.
  List<Task>? readPage(int page) {
    final items = _pages[page];
    if (items == null) return null;
    // Rebuilt from _byId so a later edit to one task shows in its page.
    return [for (final t in items) _byId[t.id] ?? t];
  }

  /// The saved task with [id], or null if it was never loaded.
  Task? read(int id) => _byId[id];

  void savePage(int page, List<Task> items) {
    _pages[page] = items;
    items.forEach(save);
  }

  void save(Task item) => _byId[item.id] = item;

  void remove(int id) {
    _byId.remove(id);
    _pages.updateAll((_, items) => items.where((t) => t.id != id).toList());
  }
}
