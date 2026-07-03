# Flutter Architecture

> Both `user_app` and `admin_app` follow identical architectural patterns. Differences are noted where they exist.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Folder Structure](#folder-structure)
3. [Entry Points](#entry-points)
4. [Provider Flow (State Management)](#provider-flow)
5. [Repository Pattern (Data Layer)](#repository-pattern)
6. [Core Layer](#core-layer)
   - [API Client](#api-client)
   - [Storage Service](#storage-service)
   - [Constants](#constants)
   - [Routes](#routes)
   - [Theme](#theme)
7. [Screen Structure](#screen-structure)
8. [Navigation Flow](#navigation-flow)
9. [User App vs Admin App](#user-app-vs-admin-app)

---

## Project Overview

| App | Package | Role |
|-----|---------|------|
| `user_app` | `loop_referral_network` | End-user referral network client |
| `admin_app` | `admin_app` | Administrator dashboard for approvals and settings |

Both apps:
- Target **Flutter 3.44** / Dart SDK ≥ 3.0
- Use **Provider** for state management
- Use **Repository Pattern** to abstract HTTP calls
- Use **Named routes** for navigation
- Share the same dark-mode `AppTheme`

---

## Folder Structure

```
user_app/ (or admin_app/)
└── lib/
    ├── main.dart              # App bootstrap
    ├── app.dart               # MaterialApp + MultiProvider setup
    │
    ├── core/                  # Framework-level utilities (not feature-specific)
    │   ├── constants/         # API URLs and constant strings
    │   ├── network/           # HTTP client (ApiClient)
    │   ├── routes/            # Route names and route map
    │   ├── storage/           # Local persistence (SharedPreferences)
    │   └── theme/             # AppTheme (colors, typography, component themes)
    │
    ├── models/                # Plain Dart data classes (fromJson / toJson)
    │
    ├── repositories/          # Data access layer — calls ApiClient
    │
    ├── providers/             # State management — calls repositories, notifies UI
    │
    └── screens/               # One directory per screen/feature
        ├── splash/
        ├── onboarding/
        ├── auth/
        ├── dashboard/
        ├── profile/
        ├── referral/
        ├── hierarchy/
        ├── notifications/
        ├── settings/
        └── support/
```

---

## Entry Points

### `main.dart`
Minimal entry point. Initializes Flutter binding, optionally sets preferred orientations, and runs `ReferralApp()` (or `AdminApp()`).

```dart
void main() {
  runApp(const ReferralApp());
}
```

### `app.dart`
The root widget. Wraps the entire widget tree in `MultiProvider` and configures `MaterialApp` with the dark theme, initial route, and named route map.

```dart
class ReferralApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => HierarchyProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
```

All providers are registered at the app root so they are available throughout the entire widget tree.

---

## Provider Flow

The app uses the **Provider** package (`ChangeNotifier`) for state management.

### Architecture Pattern

```
Widget (UI)
    │
    │ calls Provider.of<XProvider>(context) or context.read<XProvider>().method()
    ▼
Provider (ChangeNotifier)
    │ holds state, calls repository, calls notifyListeners()
    ▼
Repository
    │ calls ApiClient
    ▼
ApiClient (HTTP)
    │
    ▼
Backend API
```

### State Machine in Providers

Every provider follows this pattern:

```dart
class ExampleProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  SomeData? _data;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SomeData? get data => _data;

  Future<void> fetchData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.getData();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### User App Providers

| Provider | State It Manages |
|----------|----------------|
| `AuthProvider` | `UserModel? user`, `isLoading`, `errorMessage`. Handles login, register, logout, `tryAutoLogin()` |
| `DashboardProvider` | Dashboard summary stats (points, referral count, recent signups) |
| `ProfileProvider` | User profile data, avatar upload state |
| `ReferralProvider` | List of user's referrals |
| `HierarchyProvider` | Downline tree data |
| `NotificationProvider` | Notification list, unread count |

### Admin App Providers

| Provider | State It Manages |
|----------|----------------|
| `AuthProvider` | Same as user app — admin login/logout |
| `AdminDashboardProvider` | System-wide stats |
| `AdminApprovalsProvider` | Pending referral list, approve/reject actions |
| `AdminUsersProvider` | Full user list with search and soft-delete |
| `AdminSettingsProvider` | System settings read/write |
| `AdminHierarchyProvider` | Full global hierarchy tree |

### AuthProvider Detail

```dart
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async { ... }
  Future<bool> register({ required String email, ... }) async { ... }
  Future<void> logout() async { ... }
  Future<bool> tryAutoLogin() async {
    // Reads stored JWT token → fetches /users/profile
    // Returns false if token is missing or expired
  }
  Future<void> refreshProfile() async { ... }
}
```

`tryAutoLogin()` is called during the `SplashScreen` to automatically navigate authenticated users to the dashboard without re-logging in.

---

## Repository Pattern

Repositories are plain Dart classes that:
1. Accept method parameters.
2. Call `ApiClient` methods with the correct endpoint and payload.
3. Parse and return typed model objects.
4. Throw `Exception` on API error responses.

Repositories contain **no UI logic** and **no state**.

### User App Repositories

| Repository | Endpoints It Calls |
|-----------|-------------------|
| `AuthRepository` | `POST /auth/login`, `POST /auth/register`, `POST /auth/logout` |
| `UserRepository` | `GET /users/profile` |
| `ProfileRepository` | `PUT /profile`, `POST /profile/avatar` (multipart) |
| `ReferralRepository` | `GET /referrals/my`, `GET /referrals/stats`, `GET /referrals/validate/:code` |
| `HierarchyRepository` | `GET /hierarchy/my` |
| `NotificationRepository` | `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` |

### Example: `AuthRepository`

```dart
class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });

    final data = response['data'];
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    await _storage.saveToken(token);
    await _storage.saveUser(user.id, user.email);

    return user;
  }
}
```

---

## Core Layer

### API Client

`core/network/api_client.dart` is the single HTTP entry point for the app.

**Responsibilities:**
- Prepends `ApiConstants.baseUrl` to all endpoint paths.
- Automatically reads the JWT token from `StorageService` and adds `Authorization: Bearer <token>` to every request.
- Encodes request bodies as JSON.
- Decodes all responses as JSON.
- Throws `Exception(message)` for non-2xx responses.

**Methods:**

| Method | Usage |
|--------|-------|
| `get(endpoint, {queryParams})` | GET requests |
| `post(endpoint, body)` | POST JSON requests |
| `put(endpoint, body)` | PUT JSON requests |
| `patch(endpoint, body)` | PATCH JSON requests |
| `delete(endpoint)` | DELETE requests |
| `uploadAvatar(fileBytes, fileName)` | Multipart POST for avatar upload |

The `uploadAvatar` method uses `http.MultipartRequest` instead of the standard JSON flow.

### Storage Service

`core/storage/storage_service.dart` wraps `SharedPreferences` for local persistence.

| Method | Key Stored |
|--------|-----------|
| `saveToken(token)` | `auth_token` |
| `getToken()` | `auth_token` |
| `saveUser(id, email)` | `user_id`, `user_email` |
| `clearAll()` | Clears all stored keys on logout |

### Constants

`core/constants/api_constants.dart` defines:
- `baseUrl` — the backend API base URL (set per environment).
- Endpoint path constants (e.g., `ApiConstants.login = '/auth/login'`).

This is the **only** place where the API URL is defined.

### Routes

`core/routes/app_routes.dart` defines all route name constants and the route map:

```dart
class AppRoutes {
  static const String splash      = '/';
  static const String onboarding  = '/onboarding';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String dashboard   = '/dashboard';
  static const String referrals   = '/referrals';
  static const String hierarchy   = '/hierarchy';
  static const String notifications = '/notifications';
  static const String profile     = '/profile';
  static const String settings    = '/settings';
  static const String support     = '/support';

  static Map<String, WidgetBuilder> get routes => { ... }
}
```

### Theme

`core/theme/app_theme.dart` defines the app's visual design system.

- **Mode**: Dark theme (`AppTheme.darkTheme`).
- **Colors**: Curated color palette using HSL-derived colors and gradients.
- **Typography**: Custom Google Fonts (`Inter` or `Outfit`).
- **Component themes**: Pre-configured `CardTheme`, `AppBarTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, `BottomNavigationBarTheme`.

Both `user_app` and `admin_app` use the same `AppTheme` class.

---

## Screen Structure

Each screen follows this pattern:

```
screens/
└── dashboard/
    └── dashboard_screen.dart   # StatelessWidget or ConsumerWidget
```

A screen widget:
1. Reads data from providers via `context.watch<XProvider>()` or `Consumer<XProvider>`.
2. Shows a loading indicator when `provider.isLoading == true`.
3. Shows an error message when `provider.errorMessage != null`.
4. Displays the data when available.
5. Triggers provider methods via `context.read<XProvider>().method()` in button callbacks.

---

## Navigation Flow

The app uses Flutter's named route navigation:

```
SplashScreen (/)
    │
    │ tryAutoLogin()
    ├── Token valid ──────────────→ DashboardScreen (/dashboard)
    │
    └── No token / expired
        │
        └── OnboardingScreen (/onboarding)
                │
                ├── Login → LoginScreen (/login) → DashboardScreen
                │
                └── Register → RegisterScreen (/register) → DashboardScreen
```

From the `DashboardScreen`, the user navigates via `BottomNavigationBar`:
- `Dashboard` → `/dashboard`
- `Referrals` → `/referrals`
- `Hierarchy` → `/hierarchy`
- `Notifications` → `/notifications`
- `Profile` → `/profile`

Navigation is triggered using:
```dart
Navigator.pushNamed(context, AppRoutes.referrals);
// or
Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
// or
Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
```

The last form (`pushNamedAndRemoveUntil`) is used on logout to clear the back stack.

---

## User App vs Admin App

| Feature | User App | Admin App |
|---------|----------|-----------|
| Auth | `AuthProvider` (login + register) | `AuthProvider` (login only) |
| Dashboard | Points, referral summary, QR code | System stats, recent activity |
| Referrals | Personal referral list | Pending approvals queue |
| Hierarchy | Personal downline tree | Global full tree |
| Users | Not applicable | User list with approve/delete |
| Settings | Read-only display | Read + write system settings |
| Avatar upload | Yes | No |
| Notifications | Personal notifications | Not present |
| Repositories | 6 repositories | 1 shared network + admin-specific calls |

The admin app does **not** have a `repositories/` directory. Admin providers call `ApiClient` directly or through inline data-access logic within the provider itself.
