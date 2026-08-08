# VRIDHI — Complete Final Production Inventory & Audit Record

## 1. Codebase Subsystem Inventory

### A. Backend (`backend/`)
- **Core Server & App**: `src/server.js`, `src/app.js`
- **Database ORM**: `prisma/schema.prisma` (21 Models synced with TiDB MySQL Cloud)
- **Services (15 Services)**:
  - `auth.service.js`, `user.service.js`, `profile.service.js`, `referral.service.js`, `hierarchy.service.js`
  - `language.service.js`, `languageRequest.service.js`, `video.service.js`, `product.service.js`
  - `payment.service.js`, `refund.service.js`, `productAccess.service.js`, `announcement.service.js`, `notification.service.js`, `audit.service.js`
- **Controllers (14 Controllers)**:
  - `auth.controller.js`, `user.controller.js`, `profile.controller.js`, `referral.controller.js`, `hierarchy.controller.js`
  - `language.controller.js`, `languageRequest.controller.js`, `video.controller.js`, `product.controller.js`
  - `payment.controller.js`, `refund.controller.js`, `announcement.controller.js`, `notification.controller.js`, `audit.controller.js`
- **Routes (`src/routes/v1/`)**:
  - Registered under `/api/v1`: `auth`, `users`, `profile`, `referrals`, `hierarchy`, `languages`, `language-requests`, `videos`, `products`, `payments`, `refunds`, `announcements`, `notifications`, `audit`
- **Integrations & Config**:
  - `razorpay.js` (Razorpay HMAC-SHA256 signature helper & credentials configuration)
  - `cloudinary.js` (Cloudinary API integration)
  - `database.js` (Prisma connection client)
  - `logger.js` (Pino structured logger)

### B. User App (`user_app/`)
- **State Providers**: `AuthProvider`, `DashboardProvider`, `ProfileProvider`, `ReferralProvider`, `HierarchyProvider`, `NotificationProvider`, `UserVideoProvider`, `UserPaymentProvider`
- **Screens**: `SplashScreen`, `OnboardingScreen`, `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `DashboardScreen`, `ReferralsScreen`, `HierarchyScreen`, `NotificationsScreen`, `ProfileScreen`, `SettingsScreen`, `SupportScreen`, `KycScreen`, `QrScannerScreen`, `UserVideoLibraryScreen`, `WatchHistoryScreen`, `PaymentHistoryScreen`, `UserRefundRequestScreen`

### C. Admin App (`admin_app/`)
- **State Providers**: `AuthProvider`, `AdminDashboardProvider`, `AdminApprovalsProvider`, `AdminUsersProvider`, `AdminSettingsProvider`, `AdminHierarchyProvider`, `AdminLanguagesProvider`, `AdminVideosProvider`, `AdminLanguageRequestsProvider`, `AdminProductsProvider`, `AdminPaymentsProvider`
- **Screens**: `SplashScreen`, `LoginScreen`, `DashboardScreen`, `UsersScreen`, `ApprovalsScreen`, `HierarchyScreen`, `ReportsScreen`, `SettingsScreen`, `NotificationsScreen`, `SupportScreen`, `AdminProductHubScreen`, `AdminVideoHubScreen`, `AdminVideoManagementScreen`, `AdminLanguageRequestsScreen`, `AdminProductsScreen`, `AdminVideoAnalyticsScreen`, `AdminAnnouncementsScreen`, `AdminAuditLogsScreen`, `AdminPaymentsScreen`, `AdminRefundsScreen`

---

## 2. Model & Database Verification Matrix

| Model Name | Primary Key | Key Relations | Verification Status |
|---|---|---|:---:|
| `User` | `id` (UUID) | Profile, HierarchyNode, Payments, UserProductAccess, Refunds | 🟢 VERIFIED |
| `Profile` | `id` (UUID) | User, Language (Assigned), Product (Assigned) | 🟢 VERIFIED |
| `Product` | `id` (UUID) | Videos, UserProductAccess, Payments | 🟢 VERIFIED |
| `Language` | `id` (UUID) | Videos, Profiles, UserVideoSnapshot | 🟢 VERIFIED |
| `Video` | `id` (UUID) | Language, Product, SnapshotVideo, PlaybackSession | 🟢 VERIFIED |
| `VideoVersion` | `id` (UUID) | Video (1:N Versioning) | 🟢 VERIFIED |
| `UserVideoSnapshot` | `id` (UUID) | User, Language, SnapshotVideo (Frozen Denominator) | 🟢 VERIFIED |
| `SnapshotVideo` | `id` (UUID) | Snapshot, Video | 🟢 VERIFIED |
| `Payment` | `id` (UUID) | User, Product, RefundRequest, UserProductAccess | 🟢 VERIFIED |
| `UserProductAccess` | `id` (UUID) | User, Product, Payment (Status: `PENDING_APPROVAL` $\rightarrow$ `ACTIVE`) | 🟢 VERIFIED |
| `RefundRequest` | `id` (UUID) | User, Payment, Snapshot (Status State Machine) | 🟢 VERIFIED |
| `HierarchyNode` | `id` (UUID) | User, Parent Node (Materialized Path `/root/p1/c1`) | 🟢 VERIFIED |

---

## 3. Subsystem Security & Verification Checklist

- **Razorpay Integration**: Server-side price calculation in paise (`price * 100`). HMAC-SHA256 signature verification in `razorpay.js`. Soft mock fallback in development; production strictly requires `RAZORPAY_KEY_SECRET`.
- **Product Access Authorization**: Server-side product check in `video.service.js` via `productAccessService.hasActiveAccess(userId, video.productId)` before serving video stream tokens.
- **Refund State Machine**: State transitions enforced in `refund.service.js`:
  - `PENDING` $\rightarrow$ `UNDER_REVIEW`, `APPROVED`, `REJECTED`
  - `UNDER_REVIEW` $\rightarrow$ `APPROVED`, `REJECTED`
  - `APPROVED` $\rightarrow$ `PROCESSED` (sets `Payment.status = REFUNDED`)
  - Terminal state mutation attempts (e.g. `PROCESSED` $\rightarrow$ `APPROVED`) throw a `400 Bad Request` error.
- **Snapshot Immutability**: Historical `UserVideoSnapshot` total duration and frozen video lists are immune to future video uploads, edits, or deletions.
- **Seek Protection**: `Math.max(incomingPosition, existingWatchedSecs)` prevents watched progress rewinds.
- **Hierarchy Truncation**: Standard users receive max 4-level visibility depth in `hierarchy.service.js`. Admin users receive unlimited system visibility.
