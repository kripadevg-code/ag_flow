# AG Endpoint Management Rules

## 1. Purpose

AG must provide a simple, reusable, centralized endpoint-management system without creating endpoint files for every module.

The endpoint system must:

- Keep endpoint definitions in one place.
- Allow endpoints to be reused by multiple modules and services.
- Support all HTTP methods.
- Support dynamic path parameters.
- Support query parameters.
- Support request body.
- Support headers.
- Support form-data.
- Provide complete request information to `ApiProvider`.
- Enable centralized logging, interception, error handling, and monitoring.
- Never force endpoint structure to follow frontend module hierarchy.

---

## 2. Single Endpoint File

AG must maintain only one application-level endpoint file:

```text
core/
└── endpoints.dart
```

Do NOT create:

```text
product_endpoints.dart
product_details_endpoints.dart
product_reviews_endpoints.dart
ticket_endpoints.dart
```

unless the project explicitly requires a different architecture.

The default AG architecture is:

```text
core/
├── arguments.dart
└── endpoints.dart
```

---

## 3. Endpoint Definitions Are Reusable

Endpoint definitions must be independent of modules and services.

A single endpoint may be used by:

```text
ProductService
ProductDetailsService
TicketService
RequestService
```

if those services require the same backend API.

The endpoint belongs to the API contract, not to the service.

---

## 4. Endpoint Classes

`endpoints.dart` should contain logical endpoint classes.

Example:

```dart
abstract class ProductEndpoints {
  static const products = ...;
  static const productById = ...;
  static const searchProducts = ...;
}

abstract class UserEndpoints {
  static const users = ...;
  static const userById = ...;
}

abstract class CommonEndpoints {
  static const upload = ...;
}
```

Endpoint classes should be grouped according to:

- API/domain responsibility
- Reusability
- Backend contract

They must NOT blindly follow frontend module hierarchy.

---

# 5. Frontend Hierarchy Must Not Determine Endpoint Hierarchy

This:

```text
product/
└── details/
    └── reviews/
        └── comments/
```

does NOT require:

```text
ProductEndpoints
ProductDetailsEndpoints
ProductReviewsEndpoints
ProductCommentsEndpoints
```

The backend may expose completely different APIs.

AG must allow:

```text
ProductEndpoints
CommonEndpoints
ReviewEndpoints
```

to be reused across all those services.

---

# 6. AgEndpoint and AgRequest

AG must distinguish between:

### `AgEndpoint`

A reusable API contract.

It defines the stable part of the API:

```text
Path template
Supported operation(s)
Base API configuration where applicable
```

### `AgRequest`

A concrete request created from an endpoint.

It contains request-specific values:

```text
Endpoint
HTTP method
Path parameters
Query parameters
Headers
Body
Form-data configuration
Request-specific options
```

The architecture is:

```text
AgEndpoint
    ↓
AgRequest
    ↓
ApiProvider
```

---

# 7. Dynamic Path Parameters

Dynamic path parameters must NEVER be stored as mutable values inside a reusable endpoint definition.

For example:

```text
/products/{id}
```

is the endpoint definition.

The value:

```text
id = 123
```

belongs to the actual request.

Conceptually:

```text
ProductEndpoints.productById
        ↓
AgRequest
        ↓
pathParams:
    id = 123
        ↓
/products/123
```

---

# 8. Path Parameter Resolution

AG must automatically resolve path parameters.

Given:

```text
/products/{id}
```

and:

```text
id = 123
```

AG must produce:

```text
/products/123
```

The developer must NOT manually construct:

```dart
'/products/$id'
```

inside the Service.

---

# 9. Multiple Path Parameters

AG must support multiple dynamic path parameters.

Example:

```text
/products/{productId}/reviews/{reviewId}
```

Request:

```text
productId = 100
reviewId = 25
```

Result:

```text
/products/100/reviews/25
```

The developer should only provide the parameter values.

---

# 10. Missing Path Parameters

If an endpoint requires:

```text
/products/{id}
```

but `id` is not supplied, AG must fail clearly before executing the request.

Example:

```text
Missing required path parameter: id
Endpoint: /products/{id}
```

The request must NOT be sent with an unresolved:

```text
/products/{id}
```

---

# 11. HTTP Methods

AG must support:

```text
GET
POST
PUT
PATCH
DELETE
HEAD
OPTIONS
```

and allow additional methods if required by the underlying HTTP client.

---

# 12. Same URL With Multiple Methods

A single backend path may support multiple HTTP methods.

Example:

```text
/api/product
```

may support:

```text
GET
POST
PUT
PATCH
DELETE
```

AG must support this without creating multiple URL definitions.

Conceptually:

```text
ProductEndpoints.product
        │
        ├── GET
        ├── POST
        ├── PUT
        ├── PATCH
        └── DELETE
```

The concrete `AgRequest` must identify the method being executed.

---

# 13. HTTP Method Must Be Available for Logging

The actual request must always contain its HTTP method.

`ApiProvider` must be able to log:

```text
GET /products
POST /products
PUT /products/123
DELETE /products/123
```

The method must not be hidden inside Service implementation.

This allows centralized:

- Logging
- Debugging
- Monitoring
- Request tracing
- Performance measurement
- Error reporting

---

# 14. Query Parameters

AG must support dynamic query parameters separately from path parameters.

Example endpoint:

```text
/products
```

Request:

```text
page = 2
limit = 20
search = laptop
```

Result:

```text
/products?page=2&limit=20&search=laptop
```

Query parameters must not be manually concatenated into URL strings.

---

# 15. Path Parameters vs Query Parameters

These are different concepts and must remain separate.

### Path parameter

```text
/products/{id}
```

```text
id = 123
```

### Query parameter

```text
/products?page=2
```

```text
page = 2
```

AG must maintain separate collections for them.

Conceptually:

```text
AgRequest
├── pathParams
└── queryParams
```

---

# 16. Request Body

AG must support request bodies.

Examples:

```text
POST
PUT
PATCH
```

may contain:

```json
{
  "name": "Laptop",
  "price": 50000
}
```

The body must be part of the concrete request, not the reusable endpoint definition.

---

# 17. Form Data

AG must support multipart/form-data.

Example:

```text
POST /products
Content-Type: multipart/form-data
```

with:

```text
fields
files
```

The Service should not manually construct multipart HTTP requests.

`ApiProvider` owns request execution.

---

# 18. Headers

AG must support request-specific headers.

Examples:

```text
Authorization
Content-Type
Accept
Custom headers
```

Headers that are globally applicable should be handled centrally by `ApiProvider`/interceptors.

Request-specific headers may be supplied through `AgRequest`.

---

# 19. Base URL

The reusable endpoint should not require every Service to manually provide the base URL.

Base API configuration should be managed centrally.

Conceptually:

```text
AgEndpoint
    ↓
path

ApiConfig
    ↓
base URL

AgRequest
    ↓
complete request

ApiProvider
    ↓
execute
```

This prevents duplication throughout services.

---

# 20. Service Responsibility

The Service remains responsible for API operations.

Example:

```text
ProductService
├── getAll()
├── getById()
├── add()
├── update()
├── delete()
└── search()
```

The Service should use reusable endpoint definitions.

It should NOT contain repeated raw URLs.

Bad:

```dart
final url = '/products';
```

inside every method.

Preferred:

```text
ProductEndpoints.products
```

---

# 21. Service → Endpoint → Request

The clean request flow is:

```text
ProductService
      ↓
ProductEndpoints.productById
      ↓
AgRequest
      ├── method: GET
      ├── pathParams: id = 123
      ├── queryParams: ...
      ├── headers: ...
      └── body: ...
      ↓
ApiProvider
      ↓
Backend
```

---

# 22. ApiProvider Responsibility

`ApiProvider` is the only shared HTTP execution provider.

There must be one:

```text
ApiProvider
```

AG must NOT create:

```text
ProductApiProvider
TicketApiProvider
ProductDetailsApiProvider
```

`ApiProvider` handles:

- HTTP execution
- Base URL
- Authentication
- Interceptors
- Headers
- Serialization
- Request logging
- Response logging
- Error transport handling
- Timeout
- Retry where configured
- Request tracing

---

# 23. Centralized Logging

Because every request reaches `ApiProvider`, AG can automatically log:

```text
Method
Resolved URL
Query parameters
Request duration
Status code
Response size where appropriate
Request/trace ID where available
```

Example:

```text
[API]
GET /products/123
Status: 200
Duration: 342ms
```

The developer must not manually write logging for every Service method.

---

# 24. Sensitive Data

AG must not blindly log sensitive values.

Sensitive information such as:

```text
Authorization tokens
Passwords
Secrets
Sensitive request fields
```

must be masked or excluded from logs according to application configuration.

---

# 25. Endpoint Reuse

If multiple Services require the same API endpoint, they must reuse the existing endpoint definition.

Example:

```text
ProductService
       ↓
ProductEndpoints.productById

ProductDetailsService
       ↓
ProductEndpoints.productById

RelatedProductService
       ↓
ProductEndpoints.productById
```

Do not duplicate:

```text
/products/{id}
```

in multiple locations.

---

# 26. Backend Irregularities

AG must NOT assume that backend API design follows frontend architecture.

For example:

```text
Frontend:

product/details/reviews
```

does not imply:

```text
Backend:

/product/details/reviews
```

Backend APIs may be:

```text
/api/products/{id}
/api/reviews
/api/common/search
/api/legacy/comments
```

AG must allow these APIs to be represented cleanly without changing the frontend architecture.

---

# 27. Endpoint Layer Must Remain Simple

The endpoint system must not become another large architectural subsystem.

Do NOT introduce unnecessary:

```text
EndpointRepository
EndpointService
EndpointController
EndpointFactory
EndpointManager
```

The goal is:

```text
endpoints.dart
      ↓
AgEndpoint
      ↓
AgRequest
      ↓
ApiProvider
```

Keep it simple.

---

# 28. No Endpoint Business Logic

Endpoint definitions must contain API contract information only.

They must not contain:

- Business rules
- UI logic
- Controller logic
- Repository logic
- Data transformation logic

For example:

```text
ProductEndpoints
```

must define how to reach the Product API.

It must not decide:

```text
whether a product can be deleted
```

That belongs to the appropriate business layer.

---

# 29. Endpoint Definitions Must Be Immutable

Reusable endpoint definitions should be immutable.

Dynamic request values must never mutate the global endpoint.

For example:

```text
ProductEndpoints.productById
```

must remain:

```text
/products/{id}
```

even after requesting:

```text
id = 123
```

and later:

```text
id = 456
```

Each request must create its own request-specific representation.

---

# 30. Request Isolation

Two simultaneous requests using the same endpoint must not interfere with each other.

Example:

```text
Request A
/products/123

Request B
/products/456
```

Both may use:

```text
ProductEndpoints.productById
```

but their dynamic parameters must remain completely independent.

---

# 31. Final Endpoint Architecture

The final AG architecture should be:

```text
core/
├── arguments.dart
└── endpoints.dart
```

```text
endpoints.dart
│
├── ProductEndpoints
├── UserEndpoints
├── TicketEndpoints
├── CommonEndpoints
└── ...
```

Then:

```text
Feature
   ↓
Controller
   ↓
Repo
   ↓
Service
   ↓
Reusable Endpoint
   ↓
AgRequest
   ↓
ApiProvider
   ↓
Backend
```

---

# 32. Final Principle

The endpoint system must follow this principle:

> Define the backend contract once, create request-specific values only when making a request, and execute every request through the shared ApiProvider.

In short:

```text
Endpoint
= What API contract?

Request
= What values am I sending right now?

ApiProvider
= How do I execute and monitor it?
```

This keeps the endpoint architecture reusable, dynamic, testable, loggable, and simple, without adding endpoint-file boilerplate for every module.
