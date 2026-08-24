import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service {}

class _Repo {
  const _Repo(this.service);
  final _Service service;
}

void main() {
  setUp(AgLocator.reset);

  test('put registers an eagerly-created instance, found by exact type', () {
    final service = _Service();
    AgLocator.put<_Service>(service);
    expect(AgLocator.find<_Service>(), same(service));
  });

  test('lazyPut defers construction until the first find', () {
    var callCount = 0;
    AgLocator.lazyPut<_Service>(() {
      callCount++;
      return _Service();
    });
    expect(callCount, 0);

    final first = AgLocator.find<_Service>();
    expect(callCount, 1);

    final second = AgLocator.find<_Service>();
    expect(callCount, 1, reason: 'the factory only ever runs once');
    expect(second, same(first));
  });

  test('a lazyPut factory can resolve its own dependencies via find', () {
    AgLocator.put<_Service>(_Service());
    AgLocator.lazyPut<_Repo>(() => _Repo(AgLocator.find<_Service>()));

    final repo = AgLocator.find<_Repo>();
    expect(repo.service, same(AgLocator.find<_Service>()));
  });

  test('find throws a clear error when nothing was ever registered', () {
    expect(
      AgLocator.find<_Service>,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('_Service'),
        ),
      ),
    );
  });

  test('delete removes a registered instance', () {
    AgLocator.put<_Service>(_Service());
    AgLocator.delete<_Service>();
    expect(AgLocator.find<_Service>, throwsStateError);
  });

  test('delete removes a still-pending lazyPut factory', () {
    AgLocator.lazyPut<_Service>(_Service.new);
    AgLocator.delete<_Service>();
    expect(AgLocator.find<_Service>, throwsStateError);
  });

  test('a permanent registration survives delete', () {
    final service = _Service();
    AgLocator.put<_Service>(service, permanent: true);
    AgLocator.delete<_Service>();
    expect(AgLocator.find<_Service>(), same(service));
  });

  test('deleteByType removes a registration by its raw Type', () {
    AgLocator.put<_Service>(_Service());
    AgLocator.deleteByType(_Service);
    expect(AgLocator.find<_Service>, throwsStateError);
  });
}
