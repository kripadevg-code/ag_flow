# AG Flutter CLI — Routing Rules

## 1. Purpose

The AG routing system must provide a centralized, predictable, and automatically generated routing architecture using GetX.

The developer should not manually create or maintain standard:

* Route constants
* `GetPage` registrations
* Binding registrations
* Navigation methods
* Navigation argument handling
* Route imports

The AG CLI must generate and maintain these automatically.

---

# 2. Routing Core Structure

The routing system must exist inside the application `core` layer.

```text
lib/
└── core/
    ├── arguments/
    │   └── arguments.dart
    │
    └── routes/
        ├── app_routes.dart
        ├── app_pages.dart
        └── route_management.dart
```

There must be exactly:

```text
1 × arguments.dart
1 × app_routes.dart
1 × app_pages.dart
1 × route_management.dart
```

These files are application-level routing infrastructure.

---

# 3. Single Arguments File

There must be **only one arguments file in the entire application**:

```text
core/arguments/arguments.dart
```

The CLI must create this file once during:

```bash
ag init
```

The CLI must never create:

```text
product/arguments/
product_details_argument.dart
product/details/arguments/
```

or any other argument file.

All route argument classes must be maintained inside:

```text
core/arguments/arguments.dart
```

Example:

```dart
class LoginPageArgument {
  // ...
}

class ProductDetailsPageArgument {
  final String productId;

  const ProductDetailsPageArgument({
    required this.productId,
  });
}

class ProductReviewsPageArgument {
  final String productId;

  const ProductReviewsPageArgument({
    required this.productId,
  });
}
```

When a new module requires an argument class, the CLI must update the existing `arguments.dart`.

---

# 4. AppRoutes Responsibility

`AppRoutes` is responsible only for exposing route constants.

Example:

```dart
abstract class AppRoutes {
  static const initial = _Routes.initial;

  static const splash = _Routes.splash;
  static const welcome = _Routes.welcome;
  static const intro = _Routes.intro;

  static const login = _Routes.login;
  static const ssoPage = _Routes.ssoPage;
  static const loginWithPhone = _Routes.loginWithPhone;

  static const product = _Routes.product;
  static const productDetails = _Routes.productDetails;
}

abstract class _Routes {
  static const initial = '/';

  static const splash = '/splash_page';
  static const welcome = '/welcome';
  static const intro = '/intro_page';

  static const login = '/login';
  static const ssoPage = '/sso_page';
  static const loginWithPhone = '/login_with_phone';

  static const product = '/product';
  static const productDetails = '/product/details';
}
```

The application must use:

```dart
AppRoutes.product
```

instead of:

```dart
'/product'
```

Hard-coded route strings must not be used in feature code.

---

# 5. Route Naming Convention

The route path must be derived from the module hierarchy.

For:

```bash
ag g m product
```

the route must be:

```text
/product
```

For:

```bash
ag g m product/details
```

the route must be:

```text
/product/details
```

For:

```bash
ag g m product/details/reviews
```

the route must be:

```text
/product/details/reviews
```

The CLI must derive the route automatically from the module path.

---

# 6. Route Constant Naming

The CLI must convert the route path to lower camel case.

Examples:

```text
product
→ product

product/details
→ productDetails

product/details/reviews
→ productDetailsReviews
```

Therefore:

```dart
AppRoutes.product
AppRoutes.productDetails
AppRoutes.productDetailsReviews
```

must be generated automatically.

---

# 7. AppPages Responsibility

`AppPages` is responsible for registering all `GetPage` definitions.

Example:

```dart
abstract class AppPages {
  static const defaultTransition = Transition.rightToLeft;

  static const downToUp = Transition.downToUp;

  static const downToUpDuration = Duration(
    milliseconds: 600,
  );

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: SplashPage.new,
      binding: InitialBinding(),
      transition: defaultTransition,
    ),
  ];
}
```

Every generated route must automatically be added to `AppPages.pages`.

---

# 8. GetPage Generation Rule

For every generated page, the CLI must generate a `GetPage`.

Example:

```bash
ag g m product
```

must generate:

```dart
GetPage(
  name: AppRoutes.product,
  page: ProductsPage.new,
  binding: ProductsBinding(),
  transition: AppPages.defaultTransition,
),
```

For:

```bash
ag g m product/details
```

the CLI must generate:

```dart
GetPage(
  name: AppRoutes.productDetails,
  page: ProductDetailsPage.new,
  binding: ProductDetailsBinding(),
  transition: AppPages.defaultTransition,
),
```

The developer must not manually register standard generated pages.

---

# 9. Binding Rule

Every route must have its corresponding binding.

The relationship must always be:

```text
Route
 ↓
Page
 ↓
Binding
 ↓
Controller
```

Example:

```dart
GetPage(
  name: AppRoutes.product,
  page: ProductsPage.new,
  binding: ProductsBinding(),
),
```

The CLI must automatically determine the binding from the generated module.

---

# 10. RouteManagement Responsibility

`RouteManagement` is the only recommended application-level navigation API.

Feature code should use:

```dart
RouteManagement.goToProductPage();
```

instead of:

```dart
Get.toNamed(AppRoutes.product);
```

This centralizes navigation behavior.

---

# 11. Standard Navigation Methods

For every generated page, the CLI should generate an appropriate navigation method.

For a normal page:

```dart
static void goToProductPage() {
  Get.toNamed(
    AppRoutes.product,
  );
}
```

For a detail page:

```dart
static void goToProductDetailsPage(
  ProductDetailsPageArgument argument,
) {
  Get.toNamed(
    AppRoutes.productDetails,
    arguments: argument,
  );
}
```

---

# 12. Detail Module Argument Rule

Every detail/child module must receive an argument when navigating to it.

This is a mandatory rule.

For:

```text
product/details
```

navigation must be:

```dart
RouteManagement.goToProductDetailsPage(
  ProductDetailsPageArgument(
    productId: product.id,
  ),
);
```

The following must not be generated:

```dart
RouteManagement.goToProductDetailsPage();
```

unless the module is explicitly configured as argument-free.

The default behavior for a detail/child module is:

```text
Argument Required = true
```

---

# 13. Argument Class Location

All argument classes must exist in:

```text
core/arguments/arguments.dart
```

Example:

```dart
class ProductDetailsPageArgument {
  final String productId;

  const ProductDetailsPageArgument({
    required this.productId,
  });
}

//other argument class 
```

The CLI must automatically add this class to the existing arguments file when required.

There must never be multiple argument files.

---

# 14. Detail Controller Argument Rule

The generated detail controller should retrieve its argument from GetX.

Example:

```dart
class ProductDetailsController extends AgBaseController {
  ProductDetailsController(this.productDetailsRepo);

  final ProductDetailsRepo productDetailsRepo;

  late final ProductDetailsPageArgument argument;

  @override
  void onInit() {
    super.onInit();

    argument = Get.arguments as ProductDetailsPageArgument;
  }
}
```

The CLI should automatically generate the appropriate import:

```dart
import '../../../core/arguments/arguments.dart';
```

The exact relative path must be calculated by the generator.

---

# 15. Parent-Child Routing

The CLI must understand logical module hierarchy.

Example:

```text
Product
└── Details
```

maps to:

```text
/product
/product/details
```

The physical module structure remains flat by layer.

The CLI must not create:

```text
controllers/details/
services/details/
repos/details/
pages/details/
bindings/details/
```

Instead:

```text
product/
├── bindings/
│   ├── products_binding.dart
│   └── product_details_binding.dart
│
├── controllers/
│   ├── products_controller.dart
│   └── product_details_controller.dart
│
├── services/
│   ├── products_service.dart
│   └── product_details_service.dart
│
├── repos/
│   ├── products_repo.dart
│   └── product_details_repo.dart
│
└── pages/
    ├── products_page.dart
    └── product_details_page.dart
```

The hierarchy exists logically, not through nested architectural folders.

---

# 16. Nested Route Rule

The same rule applies recursively.

Example:

```text
product
└── details
    └── reviews
        └── comments
```

routes:

```text
/product
/product/details
/product/details/reviews
/product/details/reviews/comments
```

route constants:

```dart
AppRoutes.product
AppRoutes.productDetails
AppRoutes.productDetailsReviews
AppRoutes.productDetailsReviewsComments
```

The CLI must generate these automatically.

---

# 17. Nested Detail Arguments

Every detail/child page must receive its corresponding argument.

Example:

```dart
RouteManagement.goToProductDetailsPage(
  ProductDetailsPageArgument(...),
);
```

```dart
RouteManagement.goToProductReviewsPage(
  ProductReviewsPageArgument(...),
);
```

```dart
RouteManagement.goToProductCommentsPage(
  ProductCommentsPageArgument(...),
);
```

Each argument class must exist in the single:

```text
core/arguments/arguments.dart
```

file.

---

# 18. Navigation Behavior

`RouteManagement` must support standard navigation behavior.

### Push

```dart
Get.toNamed(...)
```

### Replace

```dart
Get.offNamed(...)
```

### Clear stack

```dart
Get.offNamedUntil(
  route,
  (route) => false,
)
```

### Back

```dart
Get.back()
```

The generated navigation method should select the appropriate behavior according to the route configuration.

---

# 19. Existing Custom Navigation

The CLI must preserve custom navigation behavior.

For example:

```dart
static void goToLoginPage({
  LoginPageArgument? model,
  bool canPopCurrentRoute = false,
}) {
  Get.delete<LoginController>();

  if (canPopCurrentRoute) {
    Get.offNamed(
      AppRoutes.login,
      arguments: model,
    );
  } else {
    Get.toNamed(
      AppRoutes.login,
      arguments: model,
    );
  }
}
```

The CLI must not overwrite this simply because `login` exists.

Generated routing infrastructure and developer-customized routing logic must be treated separately.

---

# 20. Automatic Import Management

When a new route is generated, the CLI must automatically add:

* Page import
* Binding import
* Argument import when required
* Any required route-management import

The CLI must also prevent duplicate imports.

---

# 21. Duplicate Route Protection

Before generating a route, the CLI must check whether it already exists.

For example:

```bash
ag g m product/details
```

must detect:

```text
/product/details
```

if it already exists.

The CLI should report:

```text
Route already exists: /product/details
```

and must not create duplicate:

```dart
AppRoutes.productDetails
```

or duplicate:

```dart
GetPage(...)
```

---

# 22. Idempotent Routing Generation

Running:

```bash
ag g m product/details
```

multiple times must be safe.

The CLI should:

1. Detect the existing route.
2. Detect the existing page.
3. Detect the existing binding.
4. Detect the existing navigation method.
5. Detect the existing argument class.
6. Add only missing pieces.
7. Never create duplicates.
8. Never destroy developer code.

---

# 23. Route Generation Flow

When:

```bash
ag g m product/details
```

is executed, the CLI should perform:

```text
Resolve module path
        ↓
Identify parent: product
        ↓
Identify child: details
        ↓
Generate ProductDetailsPage
        ↓
Generate ProductDetailsController
        ↓
Generate ProductDetailsRepo
        ↓
Generate ProductDetailsService
        ↓
Generate ProductDetailsBinding
        ↓
Generate ProductDetailsPageArgument
        ↓
Update core/arguments/arguments.dart
        ↓
Generate /product/details
        ↓
Update AppRoutes
        ↓
Update AppPages
        ↓
Update RouteManagement
        ↓
Add required imports
        ↓
Format Dart files
        ↓
Validate generated route
```

---

# 24. Route Validation

The CLI should eventually provide:

```bash
ag analyze routes
```

or:

```bash
ag analyze
```

to validate the routing architecture.

It should detect:

* Missing route constants
* Missing `GetPage`
* Missing binding
* Missing navigation method
* Duplicate routes
* Duplicate route constants
* Missing argument classes
* Detail routes without arguments
* Incorrect route hierarchy
* Hard-coded route strings
* Missing imports

Example:

```text
ERROR: ProductDetails route requires ProductDetailsPageArgument.
```

---

# 25. Hard-Coded Route Rule

Feature code must not contain:

```dart
Get.toNamed('/product');
```

or:

```dart
Get.toNamed('/product/details');
```

The preferred approach is:

```dart
RouteManagement.goToProductPage();
```

or:

```dart
RouteManagement.goToProductDetailsPage(
  ProductDetailsPageArgument(...),
);
```

This ensures all navigation remains centralized.

---

# 26. Routing Source of Truth

The source of truth should be:

```text
Module path
```

For example:

```text
product/details/reviews
```

automatically determines:

```text
Route:
    /product/details/reviews

Route constant:
    productDetailsReviews

Page:
    ProductReviewsPage

Controller:
    ProductReviewsController

Binding:
    ProductReviewsBinding

Argument:
    ProductReviewsPageArgument

Navigation:
    goToProductReviewsPage(argument)
```

The developer should not need to define these manually.

---

# 27. Final Routing Architecture

The final routing architecture is:

```text
lib/
└── core/
    ├── arguments/
    │   └── arguments.dart
    │
    └── routes/
        ├── app_routes.dart
        ├── app_pages.dart
        └── route_management.dart
```

### `arguments.dart`

Contains all navigation argument classes.

### `app_routes.dart`

Contains all route constants.

### `app_pages.dart`

Contains all `GetPage` registrations.

### `route_management.dart`

Contains all application navigation methods.

---

# 28. Core Routing Rules

The AG CLI routing system must enforce these rules:

1. **Only one ****`arguments.dart`**** exists in the entire application.**
2. **`arguments.dart`**** is located under ****`core/arguments`****.**
3. **`AppRoutes`**** is the only source for route constants.**
4. **Hard-coded route strings are prohibited in feature code.**
5. **Every generated page must have a ****`GetPage`****.**
6. **Every generated route must have its corresponding binding.**
7. **Every generated route must have a navigation method.**
8. **Child/detail routes require an argument by default.**
9. **All argument classes are stored in the single ****`arguments.dart`****.**
10. **Parent-child routes are derived from the module path.**
11. **Architectural folders remain flat by layer.**
12. **Route generation must be idempotent.**
13. **Duplicate routes must never be generated.**
14. **Existing custom routing logic must not be overwritten.**
15. **The CLI automatically manages imports.**
16. **The CLI automatically formats generated Dart files.**
17. **The CLI should validate routing consistency.**
18. **Developers should use ****`RouteManagement`**** instead of direct ****`Get.toNamed()`**** calls.**
19. **The CLI owns standard route registration and navigation boilerplate.**
20. **The module path is the source of truth for route generation.**

---

# 29. Example

Running:

```bash
ag g m product
```

creates:

```text
/product
```

with:

```dart
AppRoutes.product
```

and:

```dart
RouteManagement.goToProductPage();
```

Running:

```bash
ag g m product/details
```

creates:

```text
/product/details
```

with:

```dart
AppRoutes.productDetails
```

and:

```dart
RouteManagement.goToProductDetailsPage(
  ProductDetailsPageArgument argument,
);
```

The argument class is added to:

```text
core/arguments/arguments.dart
```

The `GetPage` is added to:

```text
core/routes/app_pages.dart
```

The route constant is added to:

```text
core/routes/app_routes.dart
```

And the navigation method is added to:

```text
core/routes/route_management.dart
```

The developer only needs to run:

```bash
ag g m product/details
```

and the complete routing infrastructure is generated automatically.
