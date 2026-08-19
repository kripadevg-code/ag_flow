import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/module_spec.dart';
import 'package:test/test.dart';

void main() {
  group('ModulePath.parse', () {
    test('parses a root module', () {
      final path = ModulePath.parse('product');
      expect(path.segments, ['product']);
      expect(path.isRoot, isTrue);
      expect(path.depth, 0);
      expect(path.parent, isNull);
    });

    test('parses a nested module and exposes its parent', () {
      final path = ModulePath.parse('product/details/reviews');
      expect(path.segments, ['product', 'details', 'reviews']);
      expect(path.isRoot, isFalse);
      expect(path.depth, 2);
      expect(path.lastSegment, 'reviews');
      expect(path.parent, ModulePath.parse('product/details'));
    });

    test('rejects an empty path', () {
      expect(() => ModulePath.parse(''), throwsFormatException);
      expect(() => ModulePath.parse('///'), throwsFormatException);
    });

    test('rejects segments that are not lowercase snake_case', () {
      expect(() => ModulePath.parse('Product'), throwsFormatException);
      expect(() => ModulePath.parse('product-details'), throwsFormatException);
      expect(() => ModulePath.parse('product details'), throwsFormatException);
      expect(() => ModulePath.parse('123product'), throwsFormatException);
    });
  });

  group('ModuleSpec.from — naming algorithm', () {
    test(
      'a root module: layer classes/files are pluralized, but components and the raw file '
      'base are not (ag_framework.md §5 shows product_card.dart, never products_card.dart)',
      () {
        final spec = ModuleSpec.from(ModulePath.parse('product'));
        expect(spec.classPrefix, 'Products');
        expect(spec.componentClassPrefix, 'Product');
        expect(spec.routePath, '/product');
        expect(spec.routeConstant, 'product');
        expect(spec.componentNamespace, 'product');
        expect(spec.isDetail, isFalse);
        expect(spec.pageClass, 'ProductsPage');
        expect(spec.controllerClass, 'ProductsController');
        expect(spec.repoClass, 'ProductsRepo');
        expect(spec.serviceClass, 'ProductsService');
        expect(spec.bindingClass, 'ProductsBinding');
        expect(spec.navMethod, 'goToProductsPage');

        // Layer files are pluralized...
        expect(spec.layerFileBase, 'products');
        expect(spec.pageFile, 'products_page.dart');
        expect(spec.controllerFile, 'products_controller.dart');
        expect(spec.repoFile, 'products_repo.dart');
        expect(spec.serviceFile, 'products_service.dart');
        expect(spec.bindingFile, 'products_binding.dart');

        // ...but the raw file base (folder path, component file names)
        // stays singular/unpluralized.
        expect(spec.fileBase, 'product');
      },
    );

    test(
      'a 4-deep nested module: fully cumulative classes/routes, bare-leaf component namespace '
      '(the confirmed worked example from the build plan) — no pluralization applies below root',
      () {
        final spec = ModuleSpec.from(
          ModulePath.parse('product/details/reviews/comments'),
        );

        expect(spec.routePath, '/product/details/reviews/comments');
        expect(spec.routeConstant, 'productDetailsReviewsComments');
        expect(spec.classPrefix, 'ProductDetailsReviewsComments');
        expect(spec.componentClassPrefix, 'ProductDetailsReviewsComments');
        expect(spec.isDetail, isTrue);
        expect(spec.componentNamespace, 'comments');

        expect(spec.pageClass, 'ProductDetailsReviewsCommentsPage');
        expect(spec.controllerClass, 'ProductDetailsReviewsCommentsController');
        expect(spec.repoClass, 'ProductDetailsReviewsCommentsRepo');
        expect(spec.serviceClass, 'ProductDetailsReviewsCommentsService');
        expect(spec.bindingClass, 'ProductDetailsReviewsCommentsBinding');
        expect(spec.argumentClass, 'ProductDetailsReviewsCommentsPageArgument');
        expect(spec.navMethod, 'goToProductDetailsReviewsCommentsPage');

        // Below root, fileBase and layerFileBase always agree — no
        // pluralization to diverge them.
        expect(spec.fileBase, 'product_details_reviews_comments');
        expect(spec.layerFileBase, 'product_details_reviews_comments');
        expect(spec.pageFile, 'product_details_reviews_comments_page.dart');
        expect(
          spec.controllerFile,
          'product_details_reviews_comments_controller.dart',
        );
        expect(spec.repoFile, 'product_details_reviews_comments_repo.dart');
        expect(
          spec.serviceFile,
          'product_details_reviews_comments_service.dart',
        );
        expect(
          spec.bindingFile,
          'product_details_reviews_comments_binding.dart',
        );
      },
    );

    test(
      'sibling branches sharing a leaf segment name never collide on class or file name — '
      'the direct regression test for choosing the cumulative scheme over root+leaf',
      () {
        final a = ModuleSpec.from(ModulePath.parse('product/pricing/details'));
        final b = ModuleSpec.from(ModulePath.parse('product/shipping/details'));

        expect(a.classPrefix, isNot(b.classPrefix));
        expect(a.controllerFile, isNot(b.controllerFile));
        expect(a.classPrefix, 'ProductPricingDetails');
        expect(b.classPrefix, 'ProductShippingDetails');

        // Both still use the bare, non-cumulative leaf as their component
        // namespace — that part of the scheme is unaffected.
        expect(a.componentNamespace, 'details');
        expect(b.componentNamespace, 'details');
      },
    );

    test(
      'a custom pluralizer overrides the default for a root module (the --plural= escape hatch)',
      () {
        final spec = ModuleSpec.from(
          ModulePath.parse('person'),
          pluralizer: (_) => 'People',
        );
        expect(spec.classPrefix, 'People');
        expect(spec.componentClassPrefix, 'Person');
        expect(spec.layerFileBase, 'people');
        expect(spec.fileBase, 'person');
      },
    );

    test(
      'route constant is fully cumulative even though class prefix drops nothing either',
      () {
        final spec = ModuleSpec.from(ModulePath.parse('product/details'));
        expect(spec.routeConstant, 'productDetails');
        expect(spec.classPrefix, 'ProductDetails');
      },
    );
  });
}
