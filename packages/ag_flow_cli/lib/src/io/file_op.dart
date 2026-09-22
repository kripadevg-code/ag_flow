/// What happened (or would happen, under `--dry-run`) to a single file.
enum FileOpKind {
  /// The file didn't exist and was written.
  create,

  /// The file already existed and its content changed — e.g. inserting a
  /// new route constant into `app_routes.dart`.
  update,

  /// Nothing needed to change: either a fresh file already existed (left
  /// untouched, per requirments/ag_framework.md §53/§54), or an aggregator
  /// file already contained the entry this operation would have added.
  skipExisting,
}

/// A single planned (or completed) file write.
///
/// Generators never touch disk directly — they return a list of [FileOp]s,
/// which a single [Executor] either applies for real or, under
/// `--dry-run`, only reports. This also makes generators trivially
/// unit-testable without a filesystem.
class FileOp {
  const FileOp.create({
    required this.path,
    required String content,
    this.executable = false,
  }) : kind = FileOpKind.create,
       _content = content;

  const FileOp.update({required this.path, required String content})
    : kind = FileOpKind.update,
      executable = false,
      _content = content;

  const FileOp.skipExisting({required this.path})
    : kind = FileOpKind.skipExisting,
      executable = false,
      _content = null;

  /// The absolute path this operation targets.
  final String path;

  final FileOpKind kind;

  /// Whether the written file needs the executable bit — a git hook is
  /// ignored by git without it.
  final bool executable;

  final String? _content;

  /// The file content to write. Only present for [FileOpKind.create] and
  /// [FileOpKind.update].
  String get content {
    final content = _content;
    if (content == null) {
      throw StateError(
        'FileOp.content is only available for create/update ($path)',
      );
    }
    return content;
  }
}
