/// Wraps an unexpected error raised while a repository ran its Service
/// call, via `AgBaseRepo.guard`.
class AgRepoException implements Exception {
  const AgRepoException(this.cause);

  /// The original error that was caught.
  final Object cause;

  @override
  String toString() => 'AgRepoException: $cause';
}
