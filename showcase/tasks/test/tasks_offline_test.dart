import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';
import 'package:ag_showcase_tasks/modules/tasks/stores/tasks_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Service whose reads either return [tasks] or throw [error].
class _FakeService extends TasksService {
  _FakeService() : super(ApiProvider(baseUrl: 'http://unused'));

  List<Task> tasks = const [];
  Object? error;

  @override
  Future<List<Task>> list({int page = 1}) async {
    if (error case final e?) throw e;
    return tasks;
  }

  @override
  Future<Task> retrieve(int id) async {
    if (error case final e?) throw e;
    return tasks.firstWhere((t) => t.id == id);
  }

  @override
  Future<Task> update(int id, Task item) async {
    if (error case final e?) throw e;
    return item;
  }
}

const _offline = AgApiException(
  message: 'offline',
  type: AgApiErrorType.connection,
);
const _serverError = AgApiException(
  message: 'boom',
  statusCode: 500,
  type: AgApiErrorType.response,
);

const _task = Task(id: 1, userId: 1, title: 'Write tests', completed: false);

void main() {
  late _FakeService service;
  late TasksStore store;

  setUp(() {
    service = _FakeService()..tasks = const [_task];
    store = TasksStore();
  });

  group('TasksRepo', () {
    test('returns the saved page on a network error', () async {
      final repo = TasksRepo(service, store);
      await repo.list();

      service.error = _offline;
      expect(await repo.list(), [_task]);
    });

    test('rethrows a network error when the page was never loaded', () {
      service.error = _offline;
      expect(
        TasksRepo(service, store).list(),
        throwsA(
          isA<AgRepoException>().having(
            (e) => e.kind,
            'kind',
            AgRepoErrorKind.network,
          ),
        ),
      );
    });

    test('does not fall back on other errors', () async {
      final repo = TasksRepo(service, store);
      await repo.list();

      service.error = _serverError;
      expect(
        repo.list(),
        throwsA(
          isA<AgRepoException>().having(
            (e) => e.kind,
            'kind',
            AgRepoErrorKind.server,
          ),
        ),
      );
    });

    test('a successful update shows in the saved page', () async {
      final repo = TasksRepo(service, store);
      await repo.list();
      final done = _task.copyWith(completed: true);
      await repo.update(1, done);

      service.error = _offline;
      expect((await repo.list()).single.completed, isTrue);
    });
  });

  group('TaskDetailsRepo', () {
    test('returns a task the list saved, on a network error', () async {
      await TasksRepo(service, store).list();

      service.error = _offline;
      expect(await TaskDetailsRepo(service, store).retrieve(1), _task);
    });
  });
}
