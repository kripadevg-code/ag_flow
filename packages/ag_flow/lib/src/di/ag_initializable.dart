/// Implemented by types [AgLocator] should notify immediately after
/// realizing them — from a `lazyPut` factory, or via `put` directly.
///
/// This is what lets [AgBaseController] auto-start its initial load
/// exactly once, right after construction, without [AgLocator] itself
/// needing to know anything about controllers: `AgLocator` only ever
/// checks `is AgInitializable`, never a concrete AG type.
// ignore: one_member_abstracts
abstract class AgInitializable {
  void onAgInit();
}
