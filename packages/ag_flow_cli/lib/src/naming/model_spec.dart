import 'package:ag_flow_cli/src/naming/case_convert.dart';

/// Splits a JSON key into words, tolerating every style an API actually
/// uses: `rating_count`, `ratingCount`, `rating-count`, `RatingCount`.
///
/// The shared [pascalCase]/[camelCase] helpers deliberately take a single
/// snake_case segment and lowercase the rest of each part, so feeding them
/// `ratingCount` would yield `Ratingcount`. JSON keys are not under our
/// control, so they get their own splitter.
List<String> _keyWords(String jsonKey) {
  final separated = jsonKey.replaceAllMapped(
    RegExp('(?<=[a-z0-9])([A-Z])'),
    (match) => '_${match[1]}',
  );
  return separated
      .split(RegExp(r'[_\-\s]+'))
      .where((word) => word.isNotEmpty)
      .toList();
}

String _pascalKey(String jsonKey) => _keyWords(
  jsonKey,
).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();

String _camelKey(String jsonKey) {
  final pascal = _pascalKey(jsonKey);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

/// One field of a generated model.
class AgModelField {
  const AgModelField({
    required this.jsonKey,
    required this.dartName,
    required this.dartType,
    required this.fromJsonExpression,
    required this.toJsonExpression,
  });

  /// The key as it appears in the API payload, e.g. `rating_count`.
  final String jsonKey;

  /// The Dart field name, e.g. `ratingCount`.
  final String dartName;

  /// The Dart type, e.g. `int` or `List<ProductTag>`.
  final String dartType;

  /// Expression decoding this field from a `json` map.
  final String fromJsonExpression;

  /// Expression encoding this field back into a JSON map.
  final String toJsonExpression;
}

/// A model class to generate, plus any nested classes its fields need.
class ModelSpec {
  const ModelSpec({
    required this.className,
    required this.fields,
    this.nested = const [],
  });

  /// Infers a model from a decoded JSON sample.
  ///
  /// Accepts either a single object or a list of them (an API's list
  /// response is the most convenient thing to paste), and looks through a
  /// single-key envelope such as `{"data": [...]}` so a real response body
  /// works without being edited down first.
  factory ModelSpec.fromJsonSample(String className, Object? sample) {
    final object = _firstObjectIn(sample);
    if (object == null) {
      throw const FormatException(
        'Could not find a JSON object to model. Provide an object, a list '
        'of objects, or a response that wraps either (e.g. {"data": [...]}).',
      );
    }
    return ModelSpec._fromMap(className, object);
  }

  factory ModelSpec._fromMap(String className, Map<String, dynamic> json) {
    final fields = <AgModelField>[];
    final nested = <ModelSpec>[];

    for (final entry in json.entries) {
      fields.add(
        _resolveType(
          ownerClassName: className,
          jsonKey: entry.key,
          dartName: _fieldName(entry.key),
          value: entry.value,
          nested: nested,
        ),
      );
    }
    return ModelSpec(className: className, fields: fields, nested: nested);
  }

  /// The class name, e.g. `Product`.
  final String className;

  final List<AgModelField> fields;

  /// Classes for nested JSON objects, e.g. `ProductRating` for a
  /// `"rating": {...}` field. Rendered into the same file.
  final List<ModelSpec> nested;

  /// The snake_case file base, e.g. `product` for `Product`.
  String get fileBase => snakeCase(className);

  /// The type of this model's `id`, used as `AgCrudService`'s second type
  /// argument. Falls back to `Object` when the payload has no `id` — a
  /// module can still declare a different one by editing the Service.
  String get idType {
    for (final field in fields) {
      if (field.dartName == 'id') return field.dartType;
    }
    return 'Object';
  }

  /// Keys an API uses to wrap a payload. Only these are looked through.
  ///
  /// Unwrapping *any* single-key object would be a guess that silently
  /// models the wrong thing: `{"rating": {...}}` is a one-field model,
  /// not an envelope, and there is no way to tell the two apart from
  /// shape alone. A fixed, documented list is predictable; if a backend
  /// wraps under some other key, pass the inner object instead.
  static const _envelopeKeys = {
    'data',
    'result',
    'results',
    'payload',
    'response',
    'content',
    'records',
    'rows',
  };

  static Map<String, dynamic>? _firstObjectIn(Object? value) {
    if (value is List) {
      for (final element in value) {
        final found = _firstObjectIn(element);
        if (found != null) return found;
      }
      return null;
    }
    if (value is! Map<String, dynamic>) return null;
    if (value.length == 1 && _envelopeKeys.contains(value.keys.first)) {
      final inner = value.values.first;
      if (inner is List || inner is Map) return _firstObjectIn(inner);
    }
    return value;
  }

  static AgModelField _resolveType({
    required String ownerClassName,
    required String jsonKey,
    required String dartName,
    required Object? value,
    required List<ModelSpec> nested,
  }) {
    final read = "json['$jsonKey']";

    if (value is bool) {
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: 'bool',
        fromJsonExpression: '$read as bool',
        toJsonExpression: dartName,
      );
    }
    if (value is int) {
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: 'int',
        fromJsonExpression: '$read as int',
        toJsonExpression: dartName,
      );
    }
    if (value is double) {
      // Read through `num`: JSON gives 10 (int) for a field that is
      // conceptually a double whenever the sampled value happened to be
      // whole, and `as double` would throw on it.
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: 'double',
        fromJsonExpression: '($read as num).toDouble()',
        toJsonExpression: dartName,
      );
    }
    if (value is String) {
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: 'String',
        fromJsonExpression: '$read as String',
        toJsonExpression: dartName,
      );
    }
    if (value is Map<String, dynamic>) {
      final nestedName = '$ownerClassName${_pascalKey(jsonKey)}';
      nested.add(ModelSpec._fromMap(nestedName, value));
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: nestedName,
        fromJsonExpression:
            '$nestedName.fromJson($read as Map<String, dynamic>)',
        toJsonExpression: '$dartName.toJson()',
      );
    }
    if (value is List) {
      final first = value.isEmpty ? null : value.first;
      if (first is Map<String, dynamic>) {
        final nestedName = '$ownerClassName${_pascalKey(_singular(jsonKey))}';
        nested.add(ModelSpec._fromMap(nestedName, first));
        return AgModelField(
          jsonKey: jsonKey,
          dartName: dartName,
          dartType: 'List<$nestedName>',
          fromJsonExpression:
              '($read as List<dynamic>)\n'
              '          .map((e) => $nestedName.fromJson(e as Map<String, dynamic>))\n'
              '          .toList()',
          toJsonExpression: '$dartName.map((e) => e.toJson()).toList()',
        );
      }
      final elementType = switch (first) {
        bool() => 'bool',
        int() => 'int',
        double() => 'double',
        String() => 'String',
        _ => 'dynamic',
      };
      return AgModelField(
        jsonKey: jsonKey,
        dartName: dartName,
        dartType: 'List<$elementType>',
        fromJsonExpression: elementType == 'dynamic'
            ? '$read as List<dynamic>'
            : '($read as List<dynamic>).cast<$elementType>()',
        toJsonExpression: dartName,
      );
    }

    // null in the sample: the type is genuinely unknown, so say so rather
    // than guessing one the next payload will contradict.
    return AgModelField(
      jsonKey: jsonKey,
      dartName: dartName,
      dartType: 'Object?',
      fromJsonExpression: read,
      toJsonExpression: dartName,
    );
  }

  static String _fieldName(String jsonKey) {
    final camel = _camelKey(jsonKey);
    return _dartKeywords.contains(camel) ? '${camel}Value' : camel;
  }

  static String _singular(String word) => word.endsWith('s') && word.length > 1
      ? word.substring(0, word.length - 1)
      : word;

  static const _dartKeywords = {
    'class',
    'const',
    'default',
    'enum',
    'extends',
    'final',
    'in',
    'is',
    'new',
    'null',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'false',
    'try',
    'var',
    'void',
    'while',
    'with',
    'if',
    'else',
    'for',
  };
}
