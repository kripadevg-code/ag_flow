import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service {}

class _Repo {
  const _Repo(this.service);
  final _Service service;
}

class _DisposableService extends ChangeNotifier {
  int disposeCallCount = 0;

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
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

  test('put over an existing registration disposes the one it replaces', () {
    final replaced = _DisposableService();
    final replacement = _DisposableService();

    AgLocator.put<_DisposableService>(replaced);
    AgLocator.put<_DisposableService>(replacement);

    expect(
      replaced.disposeCallCount,
      1,
      reason:
          'the replaced instance is unreachable through the locator from '
          'that moment on, so anything still listening to it would leak for '
          'the rest of the app run',
    );
    expect(AgLocator.find<_DisposableService>(), same(replacement));
    expect(replacement.disposeCallCount, 0);
  });

  test('re-putting the very same instance does not dispose it', () {
    final service = _DisposableService();
    AgLocator.put<_DisposableService>(service);
    AgLocator.put<_DisposableService>(service);
    expect(service.disposeCallCount, 0);
    expect(AgLocator.find<_DisposableService>(), same(service));
  });
}
