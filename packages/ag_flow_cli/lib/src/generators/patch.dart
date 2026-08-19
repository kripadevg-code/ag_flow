/// A single source-text replacement, expressed as a half-open character
/// range `[offset, end)` to replace with [text].
class Patch {
  const Patch(this.offset, this.end, this.text);

  /// A pure insertion at [offset] — no existing text is replaced.
  const Patch.insertion(int offset, String text) : this(offset, offset, text);

  final int offset;
  final int end;
  final String text;
}

/// Applies [patches] to [source].
///
/// Patches are applied in descending-offset order so that an earlier
/// (lower-offset) patch's position stays valid while a later
/// (higher-offset) one is spliced in first — this is why the order
/// [patches] are supplied in doesn't matter. Overlapping patches aren't
/// supported and indicate a caller bug: two anchors should never target
/// the same source range.
String applyPatches(String source, List<Patch> patches) {
  final sorted = [...patches]..sort((a, b) => b.offset.compareTo(a.offset));
  var result = source;
  for (final patch in sorted) {
    result = result.replaceRange(patch.offset, patch.end, patch.text);
  }
  return result;
}

/// The result of attempting to idempotently update an aggregator file.
class AggregatorUpdateResult {
  const AggregatorUpdateResult.changed(this.source) : changed = true;

  const AggregatorUpdateResult.unchanged(this.source) : changed = false;

  /// Whether [source] required a change relative to the original input.
  final bool changed;

  /// The (possibly-updated) source. Callers should still reformat this
  /// before writing it back.
  final String source;
}
