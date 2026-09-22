import 'dart:convert';

import 'package:ag_flow_cli/src/generators/model_generator.dart';
import 'package:ag_flow_cli/src/naming/model_spec.dart';
import 'package:test/test.dart';

ModelSpec specFor(String className, String json) =>
    ModelSpec.fromJsonSample(className, jsonDecode(json));

void main() {
  group('ModelSpec.fromJsonSample — type inference', () {
    test('maps JSON scalars onto Dart types', () {
      final spec = specFor('Thing', '''
        {"id": 1, "name": "n", "active": true, "ratio": 1.5}''');

      expect(
        {for (final f in spec.fields) f.dartName: f.dartType},
        {'id': 'int', 'name': 'String', 'active': 'bool', 'ratio': 'double'},
      );
    });

    test('reads a double through num, not a direct cast', () {
      final spec = specFor('Thing', '{"ratio": 1.5}');

      expect(
        spec.fields.single.fromJsonExpression,
        "(json['ratio'] as num).toDouble()",
        reason:
            'the next payload may send a whole number for the same '
            'field, and `as double` would throw on it',
      );
    });

    test('a null sample value yields Object?, not a guessed type', () {
      final spec = specFor('Thing', '{"deletedAt": null}');

      expect(spec.fields.single.dartType, 'Object?');
    });

    test('converts snake_case keys to camelCase but keeps the JSON key', () {
      final spec = specFor('Thing', '{"published_at": "x"}');
      final field = spec.fields.single;

      expect(field.dartName, 'publishedAt');
      expect(field.jsonKey, 'published_at');
      expect(field.fromJsonExpression, contains("json['published_at']"));
      expect(field.toJsonExpression, 'publishedAt');
    });

    test('leaves an already-camelCase key intact', () {
      final spec = specFor('Thing', '{"userId": 1}');

      expect(spec.fields.single.dartName, 'userId');
    });

    test('renames a field that would collide with a Dart keyword', () {
      final spec = specFor('Thing', '{"class": "x"}');

      expect(spec.fields.single.dartName, 'classValue');
      expect(spec.fields.single.jsonKey, 'class');
    });

    test('generates a nested class for a nested object', () {
      final spec = specFor('Product', '{"rating": {"rate": 3.9, "count": 12}}');

      expect(spec.fields.single.dartType, 'ProductRating');
      expect(spec.nested.single.className, 'ProductRating');
      expect(
        spec.nested.single.fields.map((f) => f.dartName),
        ['rate', 'count'],
      );
    });

    test('types a list of scalars by its element type', () {
      final spec = specFor('Thing', '{"tags": ["a", "b"]}');

      expect(spec.fields.single.dartType, 'List<String>');
      expect(
        spec.fields.single.fromJsonExpression,
        contains('.cast<String>()'),
      );
    });

    test('generates a singular nested class for a list of objects', () {
      final spec = specFor('Order', '{"items": [{"sku": "a"}]}');

      expect(spec.fields.single.dartType, 'List<OrderItem>');
      expect(spec.nested.single.className, 'OrderItem');
    });

    test('an empty list falls back to dynamic elements', () {
      final spec = specFor('Thing', '{"tags": []}');

      expect(spec.fields.single.dartType, 'List<dynamic>');
    });
  });

  group('ModelSpec.fromJsonSample — finding the object', () {
    test('accepts a list response and models its first element', () {
      final spec = specFor('Post', '[{"id": 1}, {"id": 2}]');

      expect(spec.fields.single.dartName, 'id');
    });

    test('looks through a single-key envelope', () {
      // Pasting a real response body should just work, rather than
      // requiring it be edited down to the bare object first.
      final spec = specFor('Post', '{"data": [{"id": 1, "title": "t"}]}');

      expect(spec.fields.map((f) => f.dartName), ['id', 'title']);
    });

    test('does not mistake a one-field object for an envelope', () {
      final spec = specFor('Thing', '{"id": 1}');

      expect(spec.fields.single.dartName, 'id');
    });

    test('throws a clear error when there is no object to model', () {
      expect(
        () => specFor('Thing', '[1, 2, 3]'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Could not find a JSON object'),
          ),
        ),
      );
    });
  });

  group('ModelSpec.idType', () {
    test('is the type of the id field when present', () {
      expect(specFor('Thing', '{"id": 1}').idType, 'int');
      expect(specFor('Thing', '{"id": "abc"}').idType, 'String');
    });

    test('falls back to Object when the payload has no id', () {
      expect(specFor('Thing', '{"name": "n"}').idType, 'Object');
    });
  });

  group('renderModel', () {
    test('emits a const constructor, fromJson, toJson and copyWith', () {
      final source = renderModel(specFor('Post', '{"id": 1, "title": "t"}'));

      expect(source, contains('class Post {'));
      expect(source, contains('const Post({'));
      expect(
        source,
        contains('factory Post.fromJson(Map<String, dynamic> json)'),
      );
      expect(source, contains('Map<String, dynamic> toJson()'));
      expect(source, contains('Post copyWith({'));
    });

    test('renders nested classes into the same file', () {
      final source = renderModel(
        specFor('Product', '{"rating": {"rate": 3.9}}'),
      );

      expect(source, contains('class Product {'));
      expect(source, contains('class ProductRating {'));
    });

    test('does not double up the ? on an already-nullable copyWith param', () {
      final source = renderModel(specFor('Thing', '{"deletedAt": null}'));

      expect(source, contains('Object? deletedAt,'));
      expect(source, isNot(contains('Object??')));
    });
  });
}
