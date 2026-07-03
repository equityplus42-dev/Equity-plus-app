# Backend Architecture

> **Stack**: Node.js · Express.js · Prisma ORM · TiDB Cloud (MySQL) · Cloudinary · Pino · JWT

---

## Table of Contents

1. [Folder Structure](#folder-structure)
2. [Entry Points](#entry-points)
3. [Configuration Layer (`config/`)](#configuration-layer)
4. [Middleware Layer (`middleware/`)](#middleware-layer)
5. [Route Layer (`routes/`)](#route-layer)
6. [Controller Layer (`controllers/`)](#controller-layer)
7. [Service Layer (`services/`)](#service-layer)
8. [Repository Layer (`repositories/`)](#repository-layer)
9. [Utility Layer (`utils/`)](#utility-layer)
10. [Validator Layer (`validators/`)](#validator-layer)
11. [Middleware Execution Flow](#middleware-execution-flow)
12. [Request Lifecycle](#request-lifecycle)

---

## Folder Structure

```
backend/
├── prisma/
│   ├── schema.prisma          # Prisma data model definitions
│   ├── seed.js                # Database seeder script
│   └── migrations/            # Migration history (not used with TiDB push)
│
└── src/
    ├── app.js                 # Express application factory
    ├── server.js              # HTTP server boot entry point
    │
    ├── config/                # All configuration modules
    ├── controllers/           # HTTP request handlers
    ├── middleware/            # Express middleware functions
    ├── repositories/          # Database access layer (Prisma queries)
    ├── routes/                # Route definitions and mounting
    ├── services/              # Business logic layer
    ├── utils/                 # Shared helpers and utilities
    └── validators/            # Joi/Zod validation schemas
```

---

## Entry Points

### `src/server.js`
Boots the HTTP server. Reads the `PORT` from `env.js` (default `5000`). Imports the assembled Express `app` from `app.js` and calls `server.listen()`.

### `src/app.js`
The Express application factory. This file assembles the full middleware chain in a specific order and exports the `app` instance. It **never** calls `listen()` itself — that is `server.js`'s responsibility.

**Middleware order in `app.js`:**

| Order | Middleware | Purpose |
|-------|-----------|---------|
| 1 | `helmet()` | Sets security-related HTTP headers |
| 2 | `compression()` | Compresses response payloads (gzip) |
| 3 | `cors()` | Enables cross-origin resource sharing |
| 4 | `cookieParser()` | Parses incoming cookie headers |
| 5 | `express.json()` | Parses JSON request bodies |
| 6 | `express.urlencoded()` | Parses form-encoded request bodies |
| 7 | `loggerMiddleware` | Pino structured request logging |
| 8 | `rateLimit` (global) | 100 requests per 15 min window per IP |
| 9 | `swaggerUi` | Serves API docs at `/api/docs` |
| 10 | `apiRouter` | All `/api` versioned routes |
| 11 | 404 handler | Returns `{ success: false, message: "Resource not found" }` |
| 12 | `errorMiddleware` | Global error handler |

---

## Configuration Layer

All configuration modules live in `src/config/`. They are the **single source of truth** for all runtime settings.

### `env.js`
- Loads `.env` file via `dotenv`.
- Validates that `DATABASE_URL` is present (crashes the process if missing).
- Exports all environment variables with type-safe defaults.
- **All other config modules must import from `env.js`** — never from `process.env` directly.

| Export | Default | Notes |
|--------|---------|-------|
| `PORT` | `5000` | HTTP listener port |
| `NODE_ENV` | `development` | Controls logging format |
| `DATABASE_URL` | — | Required. TiDB Cloud connection string |
| `JWT_SECRET` | Hardcoded fallback | **Must be set in production** |
| `JWT_EXPIRES_IN` | `7d` | JWT expiry duration |
| `CLOUDINARY_CLOUD_NAME` | — | Optional; upload fallback if missing |
| `APP_DOMAIN` | `referral-system.com` | Used for referral URL generation |

### `database.js`
Creates and exports a singleton `PrismaClient` instance. Using a singleton prevents connection pool exhaustion — Prisma should never be instantiated more than once per process.

### `jwt.js`
Exports `{ secret, expiresIn }` sourced from `env.js`. Used by `jwt.service.js`.

### `cloudinary.js`
Calls `cloudinary.config()` with credentials from `env.js`. If credentials are missing, logs a warning and continues (upload service falls back to mock URLs during development).

### `multer.js`
Configures Multer with **`memoryStorage()`** — files are held as `Buffer` objects in `req.file.buffer`. No files are ever written to disk. File filter restricts uploads to `image/*` MIME types. Size limit: **5 MB**.

### `api.js`
Global pagination defaults (`DEFAULT_PAGE=1`, `DEFAULT_LIMIT=10`, `MAX_LIMIT=100`), rate limit window constants (100 requests / 15 min), role constants, referral status constants, and default system settings.

### `constants.js`
Exports role names (`USER`, `ADMIN`), referral status values, settings keys, and numeric default settings values. Consumed primarily by `referral.service.js`.

### `swagger.json`
Static OpenAPI 3.0.0 specification served by `swagger-ui-express` at `/api/docs`. Lists all endpoints, request/response schemas, and security requirements.

---

## Middleware Layer

### `auth.middleware.js`
JWT authentication guard. Reads the `Authorization: Bearer <token>` header, verifies the token against `jwt.config.secret`, and populates `req.user = { id, email, role }`. Returns `401` if the header is missing, malformed, expired, or invalid.

### `admin.middleware.js`
Role guard. Must be applied **after** `auth.middleware`. Checks that `req.user.role === 'ADMIN'`. Returns `403` if the user is not an administrator.

### `upload.middleware.js`
Thin wrapper that re-exports the Multer `upload.single('avatar')` call. Applied only to the avatar upload route.

### `validation.middleware.js`
Generic validation runner. Accepts a Joi/Zod schema, validates `req.body`, and calls `next()` on success or returns a `400` with field-level error details on failure.

### `rateLimit.middleware.js`
Defines three route-specific limiters:
- `loginLimiter`: 5 attempts / 60 s
- `registerLimiter`: 3 attempts / 60 s
- `forgotPasswordLimiter`: 3 attempts / 60 s

All limiters return `{ success: false, message, errorCode }` on breach (HTTP 429).

### `logger.middleware.js`
Pino-HTTP request logger. Logs method, URL, status code, and response time for every request.

### `error.middleware.js`
Express global error handler (4-argument signature). Reads `err.statusCode`, `err.message`, and `err.errorCode`. Falls back to `SYS_001` for unclassified errors. Calls `ApiResponse.error(res, message, statusCode, errorCode)`.

---

## Route Layer

### `routes/index.js`
Mounts the v1 sub-router at `/v1`:
```
/api  →  routes/index.js  →  /v1  →  routes/v1/index.js
```

### `routes/v1/index.js`
Mounts all feature routers and the `/health` endpoint:

| Path | Router File |
|------|------------|
| `/v1/auth` | `auth.routes.js` |
| `/v1/users` | `user.routes.js` |
| `/v1/admin` | `admin.routes.js` |
| `/v1/profile` | `profile.routes.js` |
| `/v1/referrals` | `referral.routes.js` |
| `/v1/hierarchy` | `hierarchy.routes.js` |
| `/v1/notifications` | `notification.routes.js` |
| `/v1/search` | `search.routes.js` |
| `/v1/settings` | `settings.routes.js` |
| `/v1/health` | Inline handler |

### Feature Route Files

| File | Protected | Admin Only |
|------|-----------|-----------|
| `auth.routes.js` | No (public) | No |
| `user.routes.js` | Yes (JWT) | Partial |
| `admin.routes.js` | Yes (JWT) | Yes |
| `profile.routes.js` | Yes (JWT) | No |
| `referral.routes.js` | Yes (JWT) | No |
| `hierarchy.routes.js` | Yes (JWT) | No |
| `notification.routes.js` | Yes (JWT) | No |
| `search.routes.js` | Yes (JWT) | No |
| `settings.routes.js` | Yes (JWT) | No |

---

## Controller Layer

Controllers are thin HTTP adapters. They extract data from `req`, call a service method, and format the response using `ApiResponse`. They never contain business logic.

| Controller | Responsibilities |
|-----------|----------------|
| `auth.controller.js` | Delegates to `authService.register/login`. Dispatches `REGISTER` / `LOGIN` audit logs. |
| `user.controller.js` | `getProfile`, `getAllUsers`, `getUserById`, `deleteUser`. Dispatches `USER_DELETE` audit log. |
| `admin.controller.js` | Dashboard stats, user approval, referral approval/rejection, settings update, referral code regeneration. Dispatches corresponding audit logs. |
| `profile.controller.js` | `updateProfile`, `uploadAvatar`. Dispatches `PROFILE_UPDATE` / `AVATAR_UPDATE` audit logs. |
| `referral.controller.js` | `getMyReferrals`, `getReferralStats`, `validateCode`. |
| `hierarchy.controller.js` | `getMyHierarchy`, `getGlobalHierarchy`. |
| `notification.controller.js` | `getNotifications`, `markRead`, `markAllRead`. |
| `search.controller.js` | User search (delegated to `search.service.js`). |
| `settings.controller.js` | Read public system settings. |

---

## Service Layer

Services implement all business logic. They are **independent of HTTP** — they receive plain data, interact with repositories, and return data or throw errors.

### `auth.service.js`
**`register(data)`**: Validates email uniqueness → validates referral code → generates a unique 8-character referral code → generates a referral URL and QR code base64 → hashes password → creates `User` + `Profile` → creates `HierarchyNode` → creates `Referral` entry if referrer present → signs and returns JWT.

**`login({ email, password })`**: Finds user by email → checks `isDeleted` flag → compares bcrypt hashes → signs and returns JWT.

### `referral.service.js`
The core reward engine.

- **`validateReferralCode(code)`**: Looks up a user by referral code. Throws if not found.
- **`createReferralEntry(refereeId, referrerId)`**: Reads system settings → determines `PENDING` or `APPROVED` status → creates `Referral` record → notifies referrer of signup → if auto-approved, immediately calls `distributePoints`.
- **`approveReferral(referralId)`**: Checks referral exists and is `PENDING` → updates to `APPROVED` → calls `distributePoints`.
- **`rejectReferral(referralId)`**: Updates status to `REJECTED` → notifies referrer.
- **`distributePoints(refereeId, refereeName, settings)`**: Reads the referee's `HierarchyNode.path` → extracts ancestor IDs → iterates up to `max_hierarchy_depth` ancestors → increments each ancestor's `points` balance → sends in-app and push notifications.

### `hierarchy.service.js`
- **`createNodeForUser(userId, parentId)`**: Reads parent node → computes new `path` and `level` → writes `HierarchyNode` record.
- **`getUserHierarchy(userId, maxDepth)`**: Reads user's node → queries all descendants with path prefix → builds nested tree structure.
- **`getGlobalHierarchy()`**: Reads all nodes → builds full system tree.

### `notification.service.js`
Writes an in-app `Notification` record to the database, then attempts to dispatch a Firebase Cloud Messaging (FCM) push notification. FCM failures are caught and logged — they never crash the request.

Notification types: `REFERRAL_SIGNUP`, `REFERRAL_APPROVED`, `REFERRAL_REJECTED`, `SYSTEM`.

### `cloudinary.service.js`
Accepts a `Buffer`, converts it to a readable stream, and pipes it to `cloudinary.uploader.upload_stream`. Returns `result.secure_url`. If Cloudinary is not configured, returns a random mock avatar URL for development convenience.

### `auditLog.service.js`
Extracts `req.ip`, `req.headers['user-agent']`, and the resolved `userId` from `req.user` or an explicit argument. Calls `auditLogRepository.createLog(...)`. **Never throws** — failures are caught and logged as warnings so that audit logging never interrupts the request.

### `jwt.service.js`
Wraps `jsonwebtoken.sign()` with the app's secret and expiry. Returns a signed JWT string.

### `search.service.js` / `userSearch.service.js` / `adminSearch.service.js`
Modular search implementations for user-facing and admin-facing search respectively. Query the `User` and `Profile` tables with `OR` conditions across email, first name, and last name.

### `firebase.service.js`
Thin wrapper around Firebase Admin SDK for dispatching FCM push notifications. Currently uses a placeholder implementation until Firebase credentials are configured.

### `qr.service.js`
Generates a QR code as a base64-encoded PNG string from a given referral URL using the `qrcode` package.

---

## Repository Layer

Repositories are the **only** layer that imports `PrismaClient`. They abstract all database queries and return plain data objects.

| Repository | Models Accessed |
|-----------|----------------|
| `auth.repository.js` | `User`, `Profile` |
| `user.repository.js` | `User`, `Profile` |
| `referral.repository.js` | `Referral`, `User`, `Profile` |
| `hierarchy.repository.js` | `HierarchyNode`, `User`, `Profile` |
| `notification.repository.js` | `Notification` |
| `profile.repository.js` | `Profile` |
| `settings.repository.js` | `SystemSettings` |
| `auditLog.repository.js` | `AuditLog` |

### `user.repository.js` — Soft Delete Behavior
- `findAll()` and `countAll()` always filter with `{ isDeleted: false }`.
- `deleteUser(id)` does **not** call `prisma.user.delete()`. Instead it calls `prisma.user.update()` to set `isDeleted: true`, `isActive: false`, and `deletedAt: new Date()`.

### `hierarchy.repository.js` — Path Prefix Queries
`findDescendants(userPath, maxLevel)` uses `path: { startsWith: "${userPath}/" }` — a prefix scan that efficiently retrieves all nodes in a user's subtree without recursive queries.

---

## Utility Layer

| File | Purpose |
|------|---------|
| `apiResponse.js` | `ApiResponse.success(res, message, data, status)` and `ApiResponse.error(res, message, status, errorCode, errors)` — the standard response wrapper used by all controllers. |
| `appError.js` | `AppError` class (extends `Error`) with `statusCode` and `errorCode` properties. `ErrorCodes` constant map for all defined error codes. |
| `encryption.js` | `hashPassword(password)` — bcrypt with salt rounds 10. `comparePassword(plain, hash)` — bcrypt compare. |
| `hierarchyHelper.js` | `buildPath(parentPath, userId)`, `getAncestorsFromPath(path)`, `buildTree(nodes, rootId)` — pure functions for materialized path manipulation. |
| `logger.js` | Wraps Pino. Pretty-prints in development. JSON output in production. Exports `{ info, warn, error, debug, logger }`. |
| `pagination.js` | `getPaginationParams(query)` extracts `page` and `limit` with defaults/caps. `formatPaginatedResponse(data, total, page, limit)` formats the standard paginated response envelope. |
| `helpers.js` | Miscellaneous helper functions shared across the codebase. |

---

## Validator Layer

Validators define request body schemas validated in `validation.middleware.js` before the request reaches controllers.

| File | Validates |
|------|-----------|
| `auth.validator.js` | `validateRegister`, `validateLogin` — email, password, optional referral code and profile fields. |

---

## Middleware Execution Flow

```
Incoming HTTP Request
       │
       ▼
  helmet()           → Sets security headers (X-Frame-Options, CSP, etc.)
       │
       ▼
  compression()      → Compresses response body
       │
       ▼
  cors()             → Validates Origin header, adds CORS headers
       │
       ▼
  cookieParser()     → Parses Cookie header into req.cookies
       │
       ▼
  express.json()     → Parses application/json body into req.body
       │
       ▼
  loggerMiddleware   → Logs request method, URL, IP
       │
       ▼
  rateLimit (global) → 100 req / 15 min (per IP)  →  429 if exceeded
       │
       ▼
  Route matching
       │
  ┌────┴────────────────────────────────┐
  │                                     │
  ▼ Public routes                      ▼ Protected routes
POST /auth/register                 authMiddleware
  │  ├─ registerLimiter                  │ Verifies JWT
  │  ├─ validationMiddleware             │ Populates req.user
  │  └─ authController.register          │
POST /auth/login                       ▼ Admin routes
  │  ├─ loginLimiter               adminMiddleware
  │  └─ authController.login             │ Checks role === 'ADMIN'
                                         │
                                         ▼
                                    Controller method
                                         │
                                         ▼
                                    Service method
                                         │
                                         ▼
                                    Repository (Prisma)
                                         │
                                         ▼
                                    TiDB Cloud Database
                                         │
                                         ▼
                                    ApiResponse.success()
                                         │
                                         ▼
                                    HTTP Response sent
       │
       ▼
  404 Handler          → Any unmatched routes
       │
       ▼
  errorMiddleware      → Catches errors thrown from any layer
                         Maps err.errorCode → structured error response
```

---

## Request Lifecycle

A complete request lifecycle for `POST /api/v1/auth/register`:

1. **TCP / TLS** — Network layer; OS accepts the connection.
2. **Express parsing** — `helmet`, `compression`, `cors`, `json` middlewares run sequentially.
3. **Pino logger** — Logs `POST /api/v1/auth/register` with timestamp.
4. **Rate limiter** — Checks IP against the global limit (100/15 min) and the `registerLimiter` (3/min).
5. **Route matching** — Express router matches `/api` → `/v1` → `/auth` → `POST /register`.
6. **Validation middleware** — Runs `validateRegister` schema against `req.body`. Returns `400` if invalid.
7. **`authController.register(req, res, next)`** — Extracts `req.body`, calls `authService.register(...)`.
8. **`authService.register(...)`** — Full business logic (email uniqueness, code generation, password hashing, user creation, hierarchy node, referral entry, JWT signing).
9. **Prisma** — Executes SQL transactions against TiDB Cloud.
10. **Audit log** — `auditLogService.log(req, 'REGISTER', user.id, ...)` writes to `AuditLog` table asynchronously.
11. **`ApiResponse.success(res, 'Registration successful', result, 201)`** — Serializes `{ success: true, message, data }` and sends HTTP 201.
12. **Error path** — If any service throws, `next(error)` propagates the error to `errorMiddleware`, which formats and returns the appropriate error response.
