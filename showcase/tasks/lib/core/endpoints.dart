import 'package:ag_flow/ag_flow.dart';

/// All API endpoint definitions for the Tasks showcase.
///
/// Grouped by backend domain, not by frontend module hierarchy
/// (ag_endpoint_rules.md §2, §5).
///
/// This app uses jsonplaceholder.typicode.com as a stand-in backend:
///   • /todos  → tasks
///   • /users  → profile / user data
///   • /posts  → projects (re-purposed to demonstrate the same patterns)
///
/// Every Service declares which endpoints it needs by referencing these
/// constants — it never constructs a URL itself.
abstract class TaskEndpoints {
  static const tasks = AgEndpoint(
    '/todos',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const taskById = AgEndpoint(
    '/todos/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
}

abstract class ProjectEndpoints {
  static const projects = AgEndpoint(
    '/posts',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const projectById = AgEndpoint(
    '/posts/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
}

abstract class UserEndpoints {
  static const me = AgEndpoint('/users/1');
}
