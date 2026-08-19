import 'package:ag_flow/src/repo/ag_repo_exception.dart';
import 'package:meta/meta.dart';

/// Base class for every AG repository.
///
/// Repositories are the concrete data-abstraction layer — AG has no
/// separate `Repo`/`RepoImpl` split. A repository calls its own Service;
/// it never talks to `ApiProvider` or an HTTP client directly.
abstract class AgBaseRepo {
  const AgBaseRepo();

  /// Runs [action], translating any exception that isn't already an
  /// [AgRepoException] into one. Optional — call this from repository
  /// methods that want centralized exception translation; passing Service
  /// exceptions straight through untouched is also valid.
  @protected
  Future<R> guard<R>(Future<R> Function() action) async {
    try {
      return await action();
    } on AgRepoException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(AgRepoException(error), stackTrace);
    }
  }
}
