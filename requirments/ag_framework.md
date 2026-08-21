# AG Framework Rules

## 1. Purpose

The AG module system is responsible for creating and maintaining standardized Flutter feature modules.

AG is not only a file generator.

AG is an opinionated Flutter framework and CLI that must:

- Generate the complete module structure.
- Automatically connect all generated layers.
- Automatically configure dependency injection.
- Automatically configure routing.
- Automatically configure navigation arguments.
- Automatically provide common page-state handling.
- Automatically provide common list behavior.
- Eliminate repetitive boilerplate.
- Preserve strict architectural separation.
- Allow developers to customize UI and business logic independently.
- Never mix UI, framework, and business logic.

The developer should focus on feature implementation rather than framework plumbing.

---

## 2. Core Principle

The primary AG principle is:

> Automate repetitive architecture, not business decisions.

AG should automatically handle everything that is standardized across modules.

The developer must remain free to implement feature-specific:

- UI
- Business logic
- Data transformations
- API-specific behavior
- Validation
- Feature-specific state
- Custom user interactions

However, these customizations must remain in their correct architectural layer.

---

## 3. Module Generation

The primary module generation command is:

```bash
ag g m <module>
```

Examples:

```bash
ag g m product
ag g m ticket
ag g m asset
```

A child module can be generated using:

```bash
ag g m product/details
```

Nested child modules are supported:

```bash
ag g m product/details/reviews
ag g m product/details/reviews/comments
```

The module path is the source of truth for:

- Module identity
- Parent/child relationship
- Class naming
- File naming
- Route naming
- Route relationship
- Detail/list relationship
- Component namespace

---

# 4. Two Primary Module Types

AG must primarily support two common business UI patterns.

## 4.1 Collection/List Module

A collection module represents a list of data.

Examples:

- Product list
- Ticket list
- Asset list
- User list
- Request list
- Service list

Example:

```bash
ag g m product
```

The generated page follows the collection pattern:

```text
ProductsPage
    ↓
AgBasePage<ProductsController>
    ↓
AgPage
    ↓
AgListBuilder
    ↓
Product Item UI
```

The developer primarily implements:

- Item UI
- Feature-specific controller behavior
- Feature-specific repository/service behavior

AG handles common collection infrastructure automatically.

## 4.2 Detail Module

A detail module represents one particular data item.

Examples:

- Product details
- Ticket details
- Asset details
- User details
- Request details

Example:

```bash
ag g m product/details
```

The generated page follows the detail pattern:

```text
ProductDetailsPage
    ↓
AgBasePage<
    ProductDetailsController,
    ProductDetailsArguments
>
    ↓
AgPage
    ↓
Detail UI
```

The developer primarily implements:

- Detail UI
- Feature-specific controller behavior
- Feature-specific repository/service behavior

AG automatically handles common detail-page infrastructure.

---

# 5. Module Structure

Every module lives under a shared `lib/modules/` parent — `lib/modules/product/`,
`lib/modules/auth/` — sitting alongside (never inside) `lib/core`. This is
filesystem organization only: it has no bearing on route paths, class
names, or any other naming rule in this document.

A complete root module must use the following structure (shown relative
to its own folder, i.e. `lib/modules/product/`):

```text
product/
├── components/
│   └── product/
│       ├── product_card.dart
│       ├── product_filter.dart
│       └── product_status.dart
│
├── bindings/
│   └── products_binding.dart
│
├── controllers/
│   └── products_controller.dart
│
├── services/
│   └── products_service.dart
│
├── repos/
│   └── products_repo.dart
│
└── pages/
    └── products_page.dart
```

A module may contain any number of components.

The component folder is therefore a namespace/container for the module's reusable UI components, not a single component file.

For a root module with child modules:

```text
product/
├── components/
│   ├── product/
│   │   ├── product_card.dart
│   │   ├── product_filter.dart
│   │   └── product_status.dart
│   │
│   ├── details/
│   │   ├── product_details_card.dart
│   │   ├── product_details_header.dart
│   │   └── product_details_info.dart
│   │
│   ├── reviews/
│   │   ├── product_review_card.dart
│   │   ├── product_review_list.dart
│   │   └── product_review_summary.dart
│   │
│   └── comments/
│       ├── product_comment_card.dart
│       ├── product_comment_input.dart
│       └── product_comment_list.dart
│
├── bindings/
│   ├── products_binding.dart
│   ├── product_details_binding.dart
│   ├── product_reviews_binding.dart
│   └── product_comments_binding.dart
│
├── controllers/
│   ├── products_controller.dart
│   ├── product_details_controller.dart
│   ├── product_reviews_controller.dart
│   └── product_comments_controller.dart
│
├── services/
│   ├── products_service.dart
│   ├── product_details_service.dart
│   ├── product_reviews_service.dart
│   └── product_comments_service.dart
│
├── repos/
│   ├── products_repo.dart
│   ├── product_details_repo.dart
│   ├── product_reviews_repo.dart
│   └── product_comments_repo.dart
│
└── pages/
    ├── products_page.dart
    ├── product_details_page.dart
    ├── product_reviews_page.dart
    └── product_comments_page.dart
```

---

# 6. Flat Architectural Layers

The following architectural folders MUST remain flat:

```text
bindings/
controllers/
services/
repos/
pages/
```

All child module artifacts must be placed into the corresponding shared folder.

For example:

```text
controllers/
├── products_controller.dart
├── product_details_controller.dart
├── product_reviews_controller.dart
└── product_comments_controller.dart
```

Do NOT create:

```text
controllers/details/
controllers/details/reviews/
controllers/details/reviews/comments/
```

Likewise, do NOT create nested folders under:

```text
bindings/
services/
repos/
pages/
```

The parent/child relationship is logical and routing-based, not represented by nested architectural directories.

---

# 7. Component Folder Rule

`components/` is different from the other architectural folders.

Components must be grouped by their owning module because a module can contain multiple reusable UI components.

For:

```text
product
```

use:

```text
components/product/
```

For:

```text
product/details
```

use:

```text
components/details/
```

For:

```text
product/details/reviews
```

use:

```text
components/reviews/
```

For:

```text
product/details/reviews/comments
```

use:

```text
components/comments/
```

Each component namespace may contain any number of component files.

Example:

```text
components/details/
├── product_details_card.dart
├── product_details_header.dart
├── product_details_info.dart
└── product_details_actions.dart
```

Do NOT create:

```text
components/details/reviews/
components/details/reviews/comments/
```

The component namespace is always directly under the shared `components/` folder.

Therefore:

```text
Module: product
→ components/product/

Module: product/details
→ components/details/

Module: product/details/reviews
→ components/reviews/

Module: product/details/reviews/comments
→ components/comments/
```

This rule is mandatory.

---

# 8. Logical Module Hierarchy vs Physical Structure

AG must distinguish between logical module hierarchy and filesystem structure.

A logical module relationship may be:

```text
Product
└── Details
    └── Reviews
        └── Comments
```

This does NOT mean the filesystem should be:

```text
product/
└── details/
    └── reviews/
        └── comments/
```

The physical architecture remains:

```text
product/
├── components/
│   ├── product/
│   ├── details/
│   ├── reviews/
│   └── comments/
│
├── bindings/
├── controllers/
├── services/
├── repos/
└── pages/
```

The hierarchy is represented by:

- Module path
- Naming
- Route relationship
- Parent/child ownership
- Component namespace

It is NOT represented by nested architectural folders.

---

# 9. Parent Module Requirement

A child module should only be created when its parent module exists.

Example:

```bash
ag g m product/details
```

requires:

```text
product
```

to already exist.

If the parent does not exist, the CLI must report the missing parent instead of silently creating an invalid hierarchy.

Example:

```text
ERROR: Parent module "product" does not exist.

Create it first:

ag g m product
```

---

# 10. Module Naming Rules

Module names must:

- Use lowercase.
- Use `snake_case` for multi-word names.
- Not contain spaces.
- Not contain invalid Dart characters.
- Not use reserved module names.
- Produce valid Dart class names.

Examples:

```text
product
ticket
service_catalogue
request_dashboard
product_details
```

Class names must be generated using PascalCase.

Example:

```text
product_details
```

becomes:

```text
ProductDetails
```

Generated classes:

```text
ProductDetailsPage
ProductDetailsController
ProductDetailsRepo
ProductDetailsService
ProductDetailsBinding
```

---

# 11. Complete Layer Responsibility

Every layer has one clear responsibility.

```text
Page
    ↓
UI composition

Controller
    ↓
Feature state + feature orchestration + feature business logic

Repo
    ↓
Repository/data abstraction

Service
    ↓
API/data communication

Binding
    ↓
Dependency injection

Component
    ↓
Reusable UI
```

The dependency direction is:

```text
Page
  ↓
Controller
  ↓
Repo
  ↓
Service
  ↓
ApiProvider
```

This direction must not be violated.

---

# 12. Page Rules

Pages are responsible for UI composition.

Pages must not directly access:

- Repository
- Service
- ApiProvider
- Dio
- Network clients

A page should communicate with its controller.

The generated page must use the appropriate AG base page contract.

---

# 13. AgBasePage

`AgBasePage` is the common page-level framework abstraction.

Its responsibility is to provide common page behavior automatically.

AG must use sensible defaults for:

- Loading
- Error
- Empty
- Refresh
- Retry
- Common page state handling
- Common lifecycle behavior

The developer should not have to implement these repeatedly for every page.

---

# 14. Page State Automation

AG must automatically handle common page states.

Default behavior:

```text
Loading → AG default loading UI
Error   → AG default error UI
Empty   → AG default empty UI
Success → Page content
Refresh → AG default refresh behavior
Retry   → AG default retry behavior
```

The developer should not have to repeatedly write:

```text
if loading
if error
if empty
if success
if refreshing
```

for every module.

This is framework responsibility.

---

# 15. Independent Page Customization

AG defaults must always be individually overridable.

The developer must be able to customize only one behavior without replacing the others.

Example:

```text
Loading → AG default
Error   → Custom
Empty   → AG default
Refresh → AG default
```

Another page may use:

```text
Loading → Custom
Error   → Custom
Empty   → AG default
Refresh → Custom
```

The developer must not be forced to replace the entire `AgPage` just to customize one state.

---

# 16. Default AG Widgets

AG must provide reusable default widgets such as:

```text
AgLoading
AgError
AgEmpty
```

These are framework defaults.

The developer may override them when required.

AG should provide additional reusable widgets over time where repeated application patterns justify them.

---

# 17. AgListBuilder

`AgListBuilder` is the standard AG widget for collection/list rendering.

Its responsibility is limited to collection behavior.

`AgListBuilder` must handle:

- Rendering collection items
- List scrolling
- Load more
- Pagination/collection continuation
- Load-more state

`AgListBuilder` must NOT own page-level:

- Loading
- Error
- Empty
- Business logic
- API calls

These belong elsewhere.

---

# 18. AgListBuilder Responsibility Boundary

The distinction must remain:

```text
AgPage
    ↓
"What state is this page in?"

AgListBuilder
    ↓
"How should this collection be rendered and continued?"
```

Therefore:

```text
AgPage
├── Loading
├── Error
├── Empty
├── Retry
├── Refresh
└── Success
       ↓
   AgListBuilder
       ├── Items
       ├── Scroll
       └── Load More
```

This separation is mandatory.

---

# 19. Collection Page Flow

A collection page should conceptually work as:

```text
ProductsPage
    ↓
AgBasePage<ProductsController>
    ↓
AgPage
    ├── Loading
    ├── Error
    ├── Empty
    └── Success
           ↓
      AgListBuilder
           ↓
      ProductCard
```

The developer should mainly provide the item UI and feature-specific behavior.

---

# 20. Detail Page Flow

A detail page should conceptually work as:

```text
ProductDetailsPage
    ↓
AgBasePage<
    ProductDetailsController,
    ProductDetailsArguments
>
    ↓
AgPage
    ├── Loading
    ├── Error
    ├── Empty
    ├── Retry
    └── Success
           ↓
        Detail UI
```

Detail pages must receive typed navigation arguments.

Detail pages must receive the same automatic page-state handling as collection pages.

There must not be a separate manually implemented loading/error/empty system for detail pages.

---

# 21. Typed Detail Arguments

A detail page must expose both:

```text
Controller
Arguments
```

through its page contract.

Conceptually:

```text
AgBasePage<
    ProductDetailsController,
    ProductDetailsArguments
>
```

This tells the developer exactly what the page requires.

The developer must not be required to manually retrieve and cast navigation arguments.

AG owns the argument resolution.

---

# 22. Single Arguments File

There must be exactly one arguments file in the application.

Location:

```text
core/
└── arguments/
    └── arguments.dart
```

AG must create this file once during project initialization.

The module generator must never create:

```text
product/arguments/
product_details_argument.dart
product/details/arguments/
```

All navigation argument classes must be maintained inside:

```text
core/arguments/arguments.dart
```

---

# 23. Argument Generation

When a detail module is generated:

```bash
ag g m product/details
```

AG must automatically ensure that the required argument class exists in:

```text
core/arguments/arguments.dart
```

The generated class must be named according to the module.

Example:

```text
ProductDetailsArguments
```

For:

```text
product/details/reviews
```

the generated argument class is:

```text
ProductDetailsReviewsArguments
```

The CLI must not create another argument file.

---

# 24. Controller Rules

Controllers must extend:

```text
AgBaseController
```

Controllers are responsible for:

- Feature state
- Feature orchestration
- Business logic
- User interaction state
- Calling repositories
- Coordinating feature behavior

Controllers must not directly access:

- ApiProvider
- Dio
- HTTP clients

Controllers communicate with repositories.

---

# 25. Base Controller Automation

`AgBaseController` must provide common framework behavior so developers do not repeatedly implement infrastructure.

Common behavior may include:

```text
Lifecycle
Page state
Loading state
Error state
Empty state
Refresh
Retry
Pagination state
Load-more state
Scroll handling
```

Feature-specific behavior belongs in the generated controller.

The developer may override base behavior when required.

---

# 26. Controller Customization

Developers must be able to freely add feature-specific business logic to controllers.

Examples:

```text
ProductController
├── loadProducts()
├── refreshProducts()
├── applyFilter()
├── searchProducts()
└── feature-specific business rules
```

This is allowed.

However, the developer must not move unrelated framework infrastructure into the controller if AG already provides it through the base controller.

---

# 27. Repository Rules

Repositories must extend:

```text
AgBaseRepo
```

Repositories are responsible for:

- Data abstraction
- Repository-level business/data decisions
- Calling services
- Mapping or coordinating data where appropriate

Repositories must not directly use:

- ApiProvider
- Dio
- HTTP clients

The repository communicates through its service.

Correct:

```text
Controller
    ↓
Repo
    ↓
Service
```

---

# 28. Service Rules

Services must extend:

```text
AgBaseService
```

Services are responsible for:

- API communication
- Endpoint definitions
- CRUD operations
- Feature-specific API methods
- Local/remote data communication where supported

Services communicate through the shared:

```text
ApiProvider
```

---

# 29. AgBaseService

`AgBaseService` is framework/base infrastructure.

Its purpose is to provide common service behavior.

Developers should not need to manually manage the base service dependency.

AG must automatically wire the required base dependencies when generating the module.

The developer should focus on:

```text
ProductService
TicketService
AssetService
```

rather than manually configuring framework infrastructure.

---

# 30. ApiProvider Rule

There must be one shared application-level:

```text
ApiProvider
```

The module generator must never create:

```text
ProductApiProvider
TicketApiProvider
AssetApiProvider
```

Every generated service ultimately uses the shared `ApiProvider`.

The `ApiProvider` is initialized during application setup.

---

# 31. Dependency Injection

Dependency injection is AG framework responsibility.

The developer should not manually wire:

```text
Service
Repo
Controller
ApiProvider
```

The generated binding must automatically connect:

```text
ApiProvider
    ↓
Service
    ↓
Repo
    ↓
Controller
```

The developer should not have to understand the internal dependency registration to use a generated module.

---

# 32. Binding Responsibility

Bindings exist primarily for dependency injection.

A generated binding must automatically wire the complete module dependency graph.

Example conceptual graph:

```text
ApiProvider
    ↓
ProductService
    ↓
ProductRepo
    ↓
ProductController
```

The developer should not manually construct these objects.

The binding is infrastructure-owned.

---

# 33. No Impl Classes

AG must NOT generate repository implementation classes such as:

```text
ProductRepoImpl
LoginRepoImpl
TicketRepoImpl
```

The repository itself is the concrete repository.

Use:

```text
ProductRepo
```

not:

```text
ProductRepo + ProductRepoImpl
```

Do not introduce interface/implementation boilerplate unless explicitly requested by the project architecture.

---

# 34. Business Logic Separation

Business logic may be customized freely by the developer.

However, business logic must remain separated from framework/UI code.

Correct:

```text
ProductPage
    ↓
ProductController
    ↓
ProductRepo
    ↓
ProductService
```

Incorrect:

```text
ProductPage
    ↓
API call
    ↓
Business calculation
    ↓
Pagination logic
```

Business logic must never be placed inside:

- AgPage
- AgListBuilder
- AgLoading
- AgError
- AgEmpty
- Generic UI components

unless the behavior is purely UI behavior.

---

# 35. UI Customization

Developers have complete freedom to customize the UI.

They may customize:

- Page layout
- App bar
- Cards
- List items
- Detail views
- Empty UI
- Error UI
- Loading UI
- Load-more UI
- Components
- Animations
- Feature-specific interactions

However, UI customization must not introduce business/API logic.

---

# 36. Components

Components are reusable UI pieces belonging to the module.

Components are grouped by module under the shared `components/` directory.

Examples:

```text
product/components/product/
product/components/details/
product/components/reviews/
product/components/comments/
```

Each component namespace may contain any number of UI component files.

Examples:

```text
product/components/product/
├── product_card.dart
├── product_filter.dart
└── product_status.dart
```

```text
product/components/details/
├── product_details_card.dart
├── product_details_header.dart
└── product_details_info.dart
```

Components may contain:

- UI
- UI-specific formatting
- UI interactions

Components must not directly call:

- Services
- Repositories
- ApiProvider

unless the architecture explicitly defines a different UI-only mechanism.

---

# 37. Component Naming and Namespace

Each module gets a component namespace directly under the shared `components/` folder.

Examples:

```text
product
→ components/product/

product/details
→ components/details/

product/details/reviews
→ components/reviews/

product/details/reviews/comments
→ components/comments/
```

Do NOT create nested component namespaces such as:

```text
components/details/reviews/
components/details/reviews/comments/
```

Every module's component namespace is a direct child of `components/`.

The namespace may contain multiple components.

---

# 38. Child Module Independence

A child module must have its own:

- Page
- Controller
- Repo
- Service
- Binding
- Route
- Arguments when required

Example:

```text
Product
└── Details
```

must generate:

```text
ProductDetailsPage
ProductDetailsController
ProductDetailsRepo
ProductDetailsService
ProductDetailsBinding
ProductDetailsArguments
```

The child must not automatically reuse the parent's controller/repository/service.

---

# 39. Parent Controller Access

A child module must NOT automatically receive or depend on the parent controller.

For example:

```text
ProductDetailsController
```

must not automatically depend on:

```text
ProductsController
```

If parent functionality is genuinely required, that dependency must be explicitly designed and implemented.

Default rule:

> Parent and child modules are independently structured.

---

# 40. Child Module Service Rule

Every child module gets its own service by default.

Example:

```text
ProductService
ProductDetailsService
ProductDetailsReviewsService
```

The child should use its own service for child-specific API operations.

Do not automatically route child API calls through the parent's service.

---

# 41. Child Module Repository Rule

Every child module gets its own repository by default.

Example:

```text
ProductRepo
ProductDetailsRepo
ProductDetailsReviewsRepo
```

The child repository communicates with its own service.

---

# 42. Child Module Controller Rule

Every child module gets its own controller.

Example:

```text
ProductsController
ProductDetailsController
ProductDetailsReviewsController
```

The child controller owns child-specific state and business behavior.

---

# 43. Collection Data Flow

Collection modules must follow:

```text
ApiProvider
    ↓
ProductService
    ↓
ProductRepo
    ↓
ProductsController
    ↓
AgBasePage
    ↓
AgListBuilder
    ↓
Product Item UI
```

The framework handles common collection infrastructure.

The developer implements feature-specific behavior.

---

# 44. Detail Data Flow

Detail modules must follow:

```text
Navigation Arguments
    ↓
ProductDetailsController
    ↓
ProductDetailsRepo
    ↓
ProductDetailsService
    ↓
ApiProvider
    ↓
Product Details State
    ↓
AgBasePage
    ↓
Detail UI
```

The framework handles:

- Argument resolution
- Page state
- Loading
- Error
- Empty
- Refresh
- Retry
- Dependency injection

The developer implements feature-specific detail behavior.

---

# 45. CRUD Service Support

Generated services should provide the standard CRUD structure where applicable:

```text
add
getAll
getById
update
delete
```

Additional feature-specific service methods may be added.

Examples:

```text
searchProduct
filterProducts
approveProduct
assignProduct
exportProduct
```

AG must not restrict feature-specific service methods.

---

# 46. Service API Responsibility

Services must own endpoint/API communication.

The controller must not construct API URLs or directly call the API provider.

The repository must not directly construct HTTP requests.

The architecture must remain:

```text
Controller
    ↓
Repo
    ↓
Service
    ↓
ApiProvider
```

---

# 47. List Load-More Responsibility

Load-more behavior belongs to the collection infrastructure.

The developer should not have to manually implement repeated:

```text
ScrollController
Detect bottom
Check loadingMore
Check hasMore
Call next page
Update loadingMore
Stop pagination
```

AG should provide this through the base controller + `AgListBuilder` infrastructure.

The developer only supplies feature-specific data loading behavior where necessary.

---

# 48. Refresh Responsibility

Refresh should be standardized by AG.

The page/widget should use the controller's refresh contract.

The developer can override feature-specific refresh behavior.

The UI should not contain API refresh logic.

---

# 49. Error Handling

Common error handling must be standardized by AG.

Default:

```text
Service/API failure
    ↓
Repo
    ↓
Controller state
    ↓
AgPage
    ↓
AgError
```

The developer can customize the UI representation of the error.

Feature-specific error/business decisions remain in the appropriate controller/repository/service layer.

---

# 50. Empty State

Empty state is a page-level state.

For a collection:

```text
API succeeds
+
No data
    ↓
AgPage
    ↓
AgEmpty
```

`AgListBuilder` must not independently implement a separate page-level empty state system.

The developer may customize the empty UI.

---

# 51. Loading State

Loading is a page-level state.

AG must provide the default:

```text
AgLoading
```

The developer may override it independently.

Collection load-more loading is separate from initial page loading.

Example:

```text
Initial API loading
    ↓
AgPage → AgLoading

Loading next page
    ↓
AgListBuilder → Load More indicator
```

These must not be treated as the same UI state.

---

# 52. Error vs Load-More Error

Initial/page-level error:

```text
AgPage
    ↓
AgError
```

Load-more error:

```text
AgListBuilder
    ↓
Load-more error/retry behavior
```

The framework must keep these behaviors separate.

---

# 53. Module Idempotency

Module generation must be idempotent.

Running:

```bash
ag g m product
```

multiple times must not:

- Duplicate files
- Duplicate classes
- Duplicate routes
- Duplicate bindings
- Duplicate argument classes
- Duplicate imports

The CLI must detect existing structures and only add missing elements.

---

# 54. Preserve Developer Code

AG must never blindly overwrite developer business logic.

The CLI owns generated infrastructure and boilerplate.

The developer owns:

- Business logic
- Feature-specific UI
- Custom service methods
- Custom repository methods
- Feature-specific controller logic

AG must preserve existing developer implementations.

---

# 55. Generated Infrastructure vs Developer Code

AG-generated infrastructure includes:

```text
Bindings
Route registration
Page registration
Dependency wiring
Arguments registration
Default page structure
Default framework integration
Generated imports
```

Developer-owned feature implementation includes:

```text
Business rules
API-specific methods
UI implementation
Custom components
Feature-specific state
Validation
```

The CLI must keep these concerns separate.

---

# 56. Automatic Imports

The CLI must automatically manage imports when generating or updating a module.

It must:

- Add required imports.
- Avoid duplicate imports.
- Resolve correct relative paths.
- Update imports when module hierarchy changes.
- Format generated Dart files.

Developers should not manually repair generated import wiring.

---

# 57. Automatic Routing Integration

When a module is generated, AG must automatically integrate it with the routing system.

The module generator must update:

```text
core/routes/app_routes.dart
core/routes/app_pages.dart
core/routes/route_management.dart
```

It must automatically create:

- Route constant
- `GetPage`
- Binding registration
- Page registration
- Navigation method

Routing rules are defined separately in `routing.md`.

---

# 58. Automatic Argument Integration

For detail modules, AG must automatically integrate the required argument into:

```text
core/arguments/arguments.dart
```

The module generator must not create another arguments file.

---

# 59. Automatic Dependency Integration

When a module is generated, AG must automatically connect:

```text
Service
Repo
Controller
Binding
```

The developer must not manually register them.

---

# 60. Automatic Page Integration

When a collection module is generated:

```text
ProductsPage
```

must automatically use:

```text
AgBasePage<ProductsController>
```

and the collection pattern:

```text
AgListBuilder
```

where appropriate.

When a detail module is generated:

```text
ProductDetailsPage
```

must automatically use:

```text
AgBasePage<
    ProductDetailsController,
    ProductDetailsArguments
>
```

---

# 61. Module Generation Should Be Opinionated

AG should prefer the framework's standard architecture instead of asking developers unnecessary configuration questions.

For a standard module, the CLI should know:

```text
Page
Controller
Repo
Service
Binding
Route
Arguments when required
AgBasePage
AgListBuilder for collection
```

The developer should only configure behavior that genuinely differs from the standard architecture.

---

# 62. Developer Customization Principle

The framework must follow:

```text
Default behavior
       ↓
Developer may override
       ↓
Only the required part changes
       ↓
Everything else remains AG default
```

Examples:

```text
Default Loading
Custom Error
Default Empty
```

or:

```text
Default List
Custom Item UI
Custom Load More UI
```

or:

```text
Default Controller lifecycle
Custom business method
```

Customization must be incremental, not all-or-nothing.

---

# 63. No Forced Framework Leakage

Developers should not need to know internal AG implementation details just to implement a feature.

The framework should hide:

- GetX registration
- GetX lookup
- Dependency graph creation
- Route registration
- Argument extraction
- Base state machinery
- Common pagination plumbing

The developer-facing API should expose the concepts they actually need:

```text
Controller
Arguments
Page
AgListBuilder
Components
Repo
Service
```

---

# 64. Business Logic Must Remain Explicit

AG must not hide business logic behind magic abstractions.

A developer should be able to clearly find:

```text
Business logic → Controller/Repo
API logic      → Service
UI logic       → Page/Component
Framework      → AgBase*/AgWidgets
```

If custom business behavior is required, the developer must be able to implement it directly in the correct layer.

---

# 65. No Business Logic in AgWidgets

`AgWidgets` must remain reusable.

Do not place feature-specific logic inside:

```text
AgListBuilder
AgLoading
AgError
AgEmpty
```

They must remain feature-independent.

For example, `AgListBuilder` must not know what a:

```text
Ticket
Product
Asset
Request
```

is.

It only knows how to render and manage a collection according to the AG collection contract.

---

# 66. No Feature Logic in AgBasePage

`AgBasePage` must remain generic.

It must not know:

```text
Product
Ticket
Asset
Request
```

or any feature-specific business rules.

It only provides common page infrastructure.

---

# 67. Framework Independence from Feature Names

AG base classes and widgets must remain generic.

Good:

```text
AgBasePage
AgBaseController
AgBaseRepo
AgBaseService
AgListBuilder
AgLoading
AgError
AgEmpty
```

Bad:

```text
ProductBasePage
TicketBaseController
ProductListBuilder
TicketLoading
```

unless explicitly created as a feature-specific component.

---

# 68. Collection and Detail Are Templates, Not Restrictions

AG's initial standardized patterns are:

```text
Collection
Detail
```

These should cover the majority of enterprise feature modules.

However, AG must not prevent developers from creating custom pages for cases such as:

```text
Dashboard
Form
Wizard
Multi-step workflow
Settings
Custom workflow
```

The framework should provide a generic `AgBasePage` foundation for such screens.

---

# 69. Framework Evolution

AG should evolve based on repeated patterns.

If a custom pattern appears repeatedly across multiple modules, it may become a new AG widget or page template.

Examples may eventually include:

```text
AgFormPage
AgDashboardPage
AgWizardPage
AgSearchBuilder
AgGridBuilder
```

Do not introduce abstractions merely for theoretical completeness.

Only standardize repeated patterns.

---

# 70. Module Validation

AG should validate generated modules against these rules.

Validation should detect:

- Missing page
- Missing controller
- Missing repo
- Missing service
- Missing binding
- Invalid dependency direction
- Direct Page → Repo access
- Direct Page → Service access
- Direct Controller → Service access
- Direct Controller → ApiProvider access
- Direct Repo → ApiProvider access
- Missing route
- Missing navigation method
- Missing detail argument
- Duplicate argument class
- Duplicate route
- Incorrect folder placement
- Incorrect class naming
- Duplicate dependency registration
- Nested architectural folders
- Nested component namespaces

---

# 71. Final Architecture

The final conceptual AG architecture is:

```text
                         AG FRAMEWORK
                              │
             ┌────────────────┼────────────────┐
             │                │                │
        AgBasePage       AgBaseController   AgWidgets
             │                │                │
             │                │          ┌─────┴─────┐
             │                │          │           │
             │                │    AgListBuilder   Other
             │                │
             └────────────────┼────────────────┘
                              │
                         FEATURE MODULE
                              │
                     ┌────────┴────────┐
                     │                 │
                    Page         Components
                     │
                     ▼
                Controller
                     │
                     ▼
                    Repo
                     │
                     ▼
                  Service
                     │
                     ▼
                ApiProvider
```

---

# 72. Physical Module Architecture

For a module tree such as:

```text
product
product/details
product/details/reviews
product/details/reviews/comments
```

the physical structure must remain:

```text
product/
├── components/
│   ├── product/
│   ├── details/
│   ├── reviews/
│   └── comments/
│
├── bindings/
│   ├── products_binding.dart
│   ├── product_details_binding.dart
│   ├── product_reviews_binding.dart
│   └── product_comments_binding.dart
│
├── controllers/
│   ├── products_controller.dart
│   ├── product_details_controller.dart
│   ├── product_reviews_controller.dart
│   └── product_comments_controller.dart
│
├── services/
│   ├── products_service.dart
│   ├── product_details_service.dart
│   ├── product_reviews_service.dart
│   └── product_comments_service.dart
│
├── repos/
│   ├── products_repo.dart
│   ├── product_details_repo.dart
│   ├── product_reviews_repo.dart
│   └── product_comments_repo.dart
│
└── pages/
    ├── products_page.dart
    ├── product_details_page.dart
    ├── product_reviews_page.dart
    └── product_comments_page.dart
```

There must be NO filesystem hierarchy like:

```text
product/
└── details/
    └── reviews/
        └── comments/
```

The module hierarchy is logical only.

---

# 73. Collection Module Contract

Every standard collection module follows:

```text
Collection
    ↓
AgBasePage<Controller>
    ↓
AgPage
    ├── Loading
    ├── Error
    ├── Empty
    └── Success
           ↓
      AgListBuilder
           ├── List rendering
           ├── Scroll
           └── Load More
                  ↓
               Item UI
```

---

# 74. Detail Module Contract

Every standard detail module follows:

```text
Detail
    ↓
Typed Arguments
    ↓
AgBasePage<Controller, Arguments>
    ↓
AgPage
    ├── Loading
    ├── Error
    ├── Empty
    ├── Retry
    └── Success
           ↓
        Detail UI
```

---

# 75. Final Developer Experience

The developer should be able to think:

```text
"I need a Product list."
```

Then:

```bash
ag g m product
```

AG creates and connects the complete module.

Then:

```text
"I need Product details."
```

Then:

```bash
ag g m product/details
```

AG creates and connects:

```text
Page
Controller
Repo
Service
Binding
Route
Arguments
Dependency Injection
Page State Handling
```

The developer then focuses on:

```text
Product UI
Product business behavior
Product API methods
Product-specific requirements
```

They should not spend time rebuilding the same infrastructure for every module.

---

# 76. Absolute Rules

The following rules are mandatory:

1. Every module must follow AG architecture.
2. Every standard module must have Page, Controller, Repo, Service, and Binding.
3. Collection modules use `AgListBuilder`.
4. Detail modules use typed page arguments.
5. `AgBasePage` owns common page-level state handling.
6. `AgListBuilder` owns collection rendering and load-more behavior.
7. `AgListBuilder` must not own page-level loading/error/empty behavior.
8. Business logic must remain outside generic AG widgets.
9. API logic must remain inside Services.
10. Repository logic must remain inside Repositories.
11. Feature state/business orchestration must remain inside Controllers.
12. UI logic must remain inside Pages/Components.
13. Dependency injection is automatically generated.
14. Routing is automatically generated.
15. Arguments are automatically generated and maintained in one global arguments file.
16. There must be only one `arguments.dart`.
17. There must be only one shared `ApiProvider`.
18. `Impl` repository classes must not be generated.
19. Parent and child modules remain logically hierarchical but physically flat.
20. All child architectural artifacts use the same shared plural folders.
21. Child module components use their own direct namespace under the shared `components/` folder.
22. Component namespaces may contain multiple components.
23. Child modules receive their own Controller, Repo, Service, Binding, and Page.
24. Child modules do not automatically depend on parent Controllers.
25. Developers can customize business logic freely within the correct layer.
26. Developers can customize UI freely without changing business logic.
27. AG defaults must be independently overridable.
28. Generated code must be idempotent.
29. Existing developer code must never be blindly overwritten.
30. Generated imports and registrations must be maintained automatically.
31. Framework code must remain feature-independent.
32. AG should automate repetitive infrastructure aggressively.
33. AG must never hide or mix feature-specific business logic with framework infrastructure.
34. Architectural folders must never become nested by child-module hierarchy.
35. Component namespaces must never become nested by child-module hierarchy.

---

# 77. Core AG Philosophy

The final rule for the AI agent is:

> If a developer has to repeatedly write the same infrastructure for every module, AG should own that infrastructure.

> If the behavior is specific to a particular business feature, the developer should own it.

Therefore:

```text
REPETITIVE + STANDARD
        ↓
       AG

FEATURE-SPECIFIC + BUSINESS
        ↓
    DEVELOPER
```

The goal is not to remove developer control.

The goal is to remove unnecessary boilerplate while preserving:

- Clear architecture
- Clear ownership
- Clear debugging
- Clear customization
- Clear business logic
- Consistent enterprise patterns
