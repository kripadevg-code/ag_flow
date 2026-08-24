import 'package:ag_flow/src/navigation/ag_navigator.dart';

/// Resolves typed navigation arguments safely.
///
/// Replaces the unsafe `AgNavigator.arguments as XArguments` cast with a
/// named, clearly-erroring lookup.
class AgArguments {
  AgArguments._();

  /// Returns [AgNavigator.arguments] cast to [A]. [override] is primarily
  /// for tests that need to supply an argument without going through a
  /// real navigation. Throws [AgArgumentError] if the value is missing or
  /// of the wrong type.
  static A resolve<A>({Object? override}) {
    final raw = override ?? AgNavigator.arguments;
    if (raw is A) return raw;
    throw AgArgumentError(expectedType: A, actualValue: raw);
  }
}

/// Thrown by [AgArguments.resolve] when the expected navigation argument
/// was not supplied, or was supplied with the wrong type.
class AgArgumentError extends Error {
  AgArgumentError({required this.expectedType, required this.actualValue});

  /// The argument type the controller expected.
  final Type expectedType;

  /// The value that was actually found (often `null`).
  final Object? actualValue;

  @override
  String toString() {
    final actualDescription = actualValue == null
        ? 'null (no arguments were passed)'
        : actualValue.runtimeType.toString();
    return 'AgArgumentError: expected a navigation argument of type '
        '$expectedType but received $actualDescription. Did you navigate '
        'via RouteManagement.goToXPage($expectedType(...))?';
  }
}
