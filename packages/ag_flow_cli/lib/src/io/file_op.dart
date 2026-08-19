/// What happened (or would happen, under `--dry-run`) to a single file.
enum FileOpKind {
  /// The file didn't exist and was written.
  create,

  /// The file already existed, so it was left untouched — this is what
  /// makes fresh-file generation idempotent (requirments/ag_framework.md
  /// §53/§54): re-running `ag g m` never clobbers a file a developer has
  /// already customized.
  skipExisting,
}

/// A single planned (or completed) file write.
///
/// Generators never touch disk directly — they return a list of [FileOp]s,
/// which a single [Executor] either applies for real or, under
/// `--dry-run`, only reports. This also makes generators trivially
/// unit-testable without a filesystem.
class FileOp {
  const FileOp.create({required this.path, required String content})
    : kind = FileOpKind.create,
      _content = content;

  const FileOp.skipExisting({required this.path})
    : kind = FileOpKind.skipExisting,
      _content = null;

  /// The absolute path this operation targets.
  final String path;

  final FileOpKind kind;

  final String? _content;

  /// The file content to write. Only present for [FileOpKind.create].
  String get content {
    final content = _content;
    if (content == null) {
      throw StateError(
        'FileOp.content is only available for FileOpKind.create ($path)',
      );
    }
    return content;
  }
}
