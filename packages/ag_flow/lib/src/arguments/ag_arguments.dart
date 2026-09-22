import 'package:ag_flow/src/navigation/ag_navigator.dart';

/// Resolves typed navigation arguments safely.
///
/// Replaces an unsafe `extra as XArgument` cast with a named,
/// clearly-erroring lookup.
///
/// Note this reads [AgNavigator.extra], which is *not* deep-link safe —
/// open the same URL cold and there is no extra to read. A detail
/// module's argument should come from the route's path parameters
/// instead; see `AgDetailController.argumentsFromPath`.
class AgArguments {
  AgArguments._();

  /// Returns [AgNavigator.extra] cast to [A]. [override] is primarily for
  /// tests that need to supply an argument without a real navigation.
  /// Throws [AgArgumentError] if the value is missing or the wrong type.
  static A resolve<A>({Object? override}) {
    final raw = override ?? AgNavigator.extra;
    if (raw is A) return raw;
    throw AgArgumentError(expectedType: A, actualValue: raw);
  }
}

/// Thrown when an expected navigation argument was not supplied, or was
/// supplied with the wrong type.
class AgArgumentError extends Error {
  AgArgumentError({
    required this.expectedType,
    required this.actualValue,
    this.pathParameters = const {},
  });

  /// The argument type the controller expected.
  final Type expectedType;

  /// The value that was actually found (often `null`).
  final Object? actualValue;

  /// The path parameters the route was entered with, if any — usually
  /// the real story when a detail page opens without its argument.
  final Map<String, String> pathParameters;

  @override
  String toString() {
    final actualDescription = actualValue == null
        ? 'null (nothing was passed)'
        : actualValue.runtimeType.toString();
    final buffer = StringBuffer(
      'AgArgumentError: expected a navigation argument of type '
      '$expectedType but received $actualDescription.',
    );
    if (pathParameters.isEmpty) {
      buffer.write(
        ' The route was entered with no path parameters either. Navigate '
        'via RouteManagement.goToXPage($expectedType(...)), or declare the '
        "argument in the route's path (e.g. '/product/:id') so the page "
        'also works from a deep link.',
      );
    } else {
      buffer.write(
        ' The route was entered with path parameters $pathParameters — '
        'override `argumentsFromPath` on this controller to build '
        '$expectedType from them.',
      );
    }
    return buffer.toString();
  }
}
