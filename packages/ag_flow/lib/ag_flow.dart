/// AG — Infraon's opinionated Flutter framework built on GetX.
///
/// See `ag_framework.md`, `routes.md`, and `ag_endpoint_rules.md` in the
/// repository's `requirments/` directory for the binding specification
/// this library implements.
library;

// Re-exported for convenience: every generated/hand-written AG module
// needs both AG's classes and GetX's (Get, Bindings, GetxController, ...).
export 'package:get/get.dart';

export 'src/arguments/ag_arguments.dart';
export 'src/controller/ag_base_controller.dart';
export 'src/controller/ag_detail_controller.dart';
export 'src/controller/ag_list_controller.dart';
export 'src/controller/ag_pagination_state.dart';
export 'src/list/ag_list_builder.dart';
export 'src/network/ag_api_exception.dart';
export 'src/network/ag_cancel_token.dart';
export 'src/network/ag_endpoint.dart';
export 'src/network/ag_http_method.dart';
export 'src/network/ag_log_options.dart';
export 'src/network/ag_logging_interceptor.dart';
export 'src/network/ag_path_resolver.dart';
export 'src/network/ag_request.dart';
export 'src/network/ag_response.dart';
export 'src/network/ag_retry_interceptor.dart';
export 'src/network/api_provider.dart';
export 'src/page/ag_base_page.dart';
export 'src/page/ag_page.dart';
export 'src/page/ag_page_state.dart';
export 'src/repo/ag_base_repo.dart';
export 'src/repo/ag_repo_exception.dart';
export 'src/service/ag_base_service.dart';
export 'src/service/ag_crud_service.dart';
export 'src/widgets/ag_empty.dart';
export 'src/widgets/ag_error.dart';
export 'src/widgets/ag_loading.dart';
