// The single application-level file for reusable API endpoint
// definitions, grouped by backend domain — not by frontend module
// hierarchy (see requirments/ag_endpoint_rules.md §2, §5). Not maintained
// automatically by `ag g m` — add your own endpoint classes here.

import 'package:ag_flow/ag_flow.dart';

abstract class PostEndpoints {
  static const posts = AgEndpoint(
    '/posts',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const postById = AgEndpoint(
    '/posts/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
  static const postComments = AgEndpoint('/posts/{id}/comments');
}
