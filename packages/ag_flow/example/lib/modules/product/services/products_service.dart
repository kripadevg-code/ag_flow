import 'package:ag_flow/ag_flow.dart';

class ProductsService extends AgBaseService {
  ProductsService(super.apiProvider);

  /// Resolves this service from [AgLocator] — no generics at call sites:
  /// ```dart
  /// final service = ProductsService.instance;
  /// ```
  static ProductsService get instance => AgLocator.find<ProductsService>();

  Future<AgListPage<dynamic, int>> getPage(int pageKey) async {
    throw UnimplementedError('ProductsService.getPage is not implemented yet.');
  }

  Future<dynamic> add(dynamic item) async {
    throw UnimplementedError('ProductsService.add is not implemented yet.');
  }

  Future<dynamic> update(dynamic id, dynamic item) async {
    throw UnimplementedError('ProductsService.update is not implemented yet.');
  }

  Future<void> delete(dynamic id) async {
    throw UnimplementedError('ProductsService.delete is not implemented yet.');
  }
}
