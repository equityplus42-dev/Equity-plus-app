# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Forgot password email flow
- Firebase authentication integration
- Unit tests for backend services
- Widget tests for Flutter screens
- Leaderboard endpoint
- Admin export reports (CSV)

---

## [1.0.0-alpha] — 2026-07-02

### Added — Backend
- Express.js 5 REST API with full `/api/v1` route structure
- Prisma ORM with TiDB Cloud (MySQL) integration
- JWT authentication with `auth.middleware.js` and `admin.middleware.js`
- Multi-level referral hierarchy using **Materialized Path** pattern
- Point distribution engine supporting up to 3 configurable reward levels
- Configurable system settings via `SystemSettings` table (admin-managed at runtime)
- Cloudinary image upload pipeline — `memoryStorage()` only, no local disk writes
- Firebase Cloud Messaging push notifications
- In-app `Notification` model with `REFERRAL_SIGNUP`, `REFERRAL_APPROVED`, `REFERRAL_REJECTED`, and `SYSTEM` types
- Rate limiting: global (100/15 min), login (5/min), register (3/min), forgot-password (3/min)
- Pino structured logging with `pino-pretty` in development
- Helmet security headers
- CORS middleware
- Swagger UI docs at `/api/docs`
- `GET /api/v1/health` endpoint with live database connectivity check
- Soft delete for user accounts (`isDeleted`, `isActive`, `deletedAt`)
- `AuditLog` table with 11 tracked action types
- Centralized error codes (`AUTH_001`–`SYS_002`) via `AppError` class
- Standard `{ success, message, data }` and `{ success, message, errorCode }` response format
- Paginated user list with search

### Added — Flutter User App
- Flutter 3.44 compatible codebase
- Dark theme with custom `AppTheme`
- Provider state management pattern (6 providers)
- Repository pattern separating HTTP calls from business logic
- Named route navigation (11 routes)
- Screens: Splash, Onboarding, Login, Register, Dashboard, Referrals, Hierarchy, Notifications, Profile, Settings, Support
- JWT token persistence via `SharedPreferences`
- Auto-login via `tryAutoLogin()` on app startup
- Avatar upload via multipart form-data
- QR code display using `qr_flutter`

### Added — Flutter Admin App
- Flutter 3.44 compatible codebase
- Dark theme (shared with user app)
- Provider state management (6 admin providers)
- Screens: Splash, Login, Dashboard, Users, Approvals, Hierarchy, Settings
- User soft-delete, approval/suspension controls
- Referral approval and rejection queue
- System settings management
- Global hierarchy tree view

### Added — Infrastructure
- GitHub Actions CI/CD workflows (3 separate workflows)
- npm cache, Flutter SDK cache, pub cache enabled
- `.gitignore` covering Node, Flutter, Android, iOS, IDEs
- Developer documentation (7 markdown files in `docs/`)
- MIT License
- Semantic Versioning CHANGELOG

### Security
- bcrypt password hashing (cost factor 10)
- JWT token expiry (default 7 days)
- No password ever returned in API responses
- Soft-deleted users cannot log in
- All security-critical actions recorded in `AuditLog`
- `pubspec.lock` and `package-lock.json` committed for reproducible builds

---

## Version History

| Version | Date | Status |
|---------|------|--------|
| 1.0.0-alpha | 2026-07-02 | Current — Alpha release |

[Unreleased]: https://github.com/YOUR_USERNAME/ReferralSystem/compare/v1.0.0-alpha...HEAD
[1.0.0-alpha]: https://github.com/YOUR_USERNAME/ReferralSystem/releases/tag/v1.0.0-alpha
