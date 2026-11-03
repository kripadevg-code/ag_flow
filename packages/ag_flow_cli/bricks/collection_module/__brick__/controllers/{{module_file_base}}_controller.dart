import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';

/// Loads the list through the Repo{{#paginate}}, one page at a time{{/paginate}}.
/// Each write goes through the Repo and then refreshes the list. Add
/// feature-specific methods (search, filter) alongside them freely.
class {{module_class_prefix}}Controller extends AgBaseController<List<{{model_class}}>>
    with {{#paginate}}AgLoadMore{{/paginate}}{{^paginate}}AgList{{/paginate}}<{{model_class}}> {
  {{module_class_prefix}}Controller(this._repo);

  final {{module_class_prefix}}Repo _repo;
{{^paginate}}
  @override
  Future<List<{{model_class}}>> list() => _repo.list();
{{/paginate}}{{#paginate}}
  @override
  Future<List<{{model_class}}>> list({int page = 1}) => _repo.list(page: page);

  @override
  bool isLastPage(List<{{model_class}}> items) => _repo.isLastPage(items);
{{/paginate}}{{#generate_create}}
  Future<void> create({{model_class}} item) async {
    await _repo.create(item);
    await refresh();
  }
{{/generate_create}}{{#generate_update}}
  Future<void> update({{id_type}} id, {{model_class}} item) async {
    await _repo.update(id, item);
    await refresh();
  }
{{/generate_update}}{{#generate_destroy}}
  Future<void> destroy({{id_type}} id) async {
    await _repo.destroy(id);
    await refresh();
  }
{{/generate_destroy}}}
