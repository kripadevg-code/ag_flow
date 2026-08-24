/// A route's push/pop transition animation — AG's own replacement for
/// GetX's `Transition` enum. Only the transitions AG's own generated
/// routing has ever used; add more here if a real need shows up.
enum AgTransition {
  /// Slides in from the right, out to the right — the default.
  rightToLeft,

  /// Cross-fades.
  fade,

  /// No animation.
  none,
}
