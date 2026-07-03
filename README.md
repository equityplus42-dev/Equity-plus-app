# Loop Referral Network

[![Backend CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/backend.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/backend.yml)
[![User App CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/user_app.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/user_app.yml)
[![Admin App CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/admin_app.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/admin_app.yml)

> A production-ready multi-level referral network platform with a Node.js backend, Flutter user app, and Flutter admin dashboard.

---

## Table of Contents

- [Project Architecture](#project-architecture)
- [Technology Stack](#technology-stack)
- [Folder Structure](#folder-structure)
- [How to Run — Backend](#how-to-run--backend)
- [How to Run — User App](#how-to-run--user-app)
- [How to Run — Admin App](#how-to-run--admin-app)
- [Deployment Instructions](#deployment-instructions)
- [Environment Variables](#environment-variables)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Loop Referral Network                     │
├────────────────┬──────────────────┬─────────────────────────┤
│   User App     │   Admin App      │       Backend API       │
│  (Flutter)     │  (Flutter)       │     (Node.js/Express)   │
├────────────────┴──────────────────┴─────────────────────────┤
│                     TiDB Cloud (MySQL)                      │
│                    via Prisma ORM                           │
├─────────────────────────────────────────────────────────────┤
│          Cloudinary (Image Storage & CDN)                   │
│          Firebase (Push Notifications)                      │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

- **Materialized Path Hierarchy** — Efficient multi-level tree traversal without recursive queries
- **Soft Delete** — User records are never permanently deleted; `isDeleted` flag controls visibility
- **Event-driven Notifications** — In-app DB notifications + Firebase FCM push notifications on every referral event
- **Configurable Rewards** — Points per level and approval mode are runtime-configurable via admin settings

---

## Technology Stack

### Backend
| Component | Technology |
|-----------|-----------|
| Runtime | Node.js 20 LTS |
| Framework | Express.js 5 |
| ORM | Prisma 7 |
| Database | TiDB Cloud (MySQL-compatible) |
| Auth | JWT (jsonwebtoken) |
| Image Upload | Cloudinary (via memory buffer — no disk storage) |
| Logging | Pino (structured JSON) |
| Security | Helmet, CORS, express-rate-limit, bcrypt |
| API Docs | Swagger UI Express |

### Mobile Apps
| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.44 (stable) |
| Language | Dart 3.x |
| State Management | Provider (ChangeNotifier) |
| HTTP Client | `package:http` |
| Local Storage | shared_preferences |
| QR Code | qr_flutter |

---

## Folder Structure

```
ReferralSystem/
├── .github/
│   └── workflows/
│       ├── backend.yml       # Backend CI (Node.js)
│       ├── user_app.yml      # User App CI (Flutter)
│       └── admin_app.yml     # Admin App CI (Flutter)
│
├── backend/                  # Node.js Express API
│   ├── prisma/               # Schema, seed, migrations
│   └── src/
│       ├── config/           # Environment, DB, JWT, Cloudinary, Multer
│       ├── controllers/      # HTTP handlers (thin layer)
│       ├── middleware/        # Auth, admin, rate-limit, validation, logger
│       ├── repositories/      # Prisma data access layer
│       ├── routes/           # Express route definitions
│       ├── services/         # Business logic
│       ├── utils/            # Helpers, logger, pagination, encryption
│       └── validators/       # Request body schemas
│
├── user_app/                 # Flutter end-user app
│   └── lib/
│       ├── core/             # Theme, routes, API client, storage, constants
│       ├── models/           # Dart data classes
│       ├── providers/        # State management (ChangeNotifier)
│       ├── repositories/      # HTTP data access layer
│       └── screens/          # Feature screens
│
├── admin_app/                # Flutter admin dashboard
│   └── lib/
│       ├── core/             # Shared theme, routes, network
│       ├── models/           # Admin-specific data classes
│       ├── providers/        # Admin state providers
│       └── screens/          # Admin feature screens
│
├── database/                 # SQL backup scripts
├── docs/                     # Developer documentation
└── postman/                  # Postman collection
```

---

## How to Run — Backend

### Prerequisites
- Node.js 20 LTS
- npm 9+
- Access to a TiDB Cloud or MySQL-compatible database

### Steps

```bash
# 1. Navigate to backend
cd backend

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env with your values (see Environment Variables below)

# 4. Apply database schema
npx prisma db push

# 5. Generate Prisma client
npx prisma generate

# 6. (Optional) Seed the database
node prisma/seed.js

# 7. Start development server
npm run dev
```

The API will be running at `http://localhost:5000`.

**API Documentation**: `http://localhost:5000/api/docs`

**Health Check**: `http://localhost:5000/api/v1/health`

---

## How to Run — User App

### Prerequisites
- Flutter SDK 3.44 (stable)
- Android Studio / Xcode (for device emulation)

### Steps

```bash
# 1. Navigate to user_app
cd user_app

# 2. Install packages
flutter pub get

# 3. Configure the API URL
# Edit: lib/core/constants/api_constants.dart
# Set baseUrl to your backend URL (e.g. http://10.0.2.2:5000/api/v1 for Android emulator)

# 4. Run on emulator/device
flutter run

# 5. Build debug APK
flutter build apk --debug
```

---

## How to Run — Admin App

### Prerequisites
- Flutter SDK 3.44 (stable)
- Android Studio / Xcode (for device emulation)

### Steps

```bash
# 1. Navigate to admin_app
cd admin_app

# 2. Install packages
flutter pub get

# 3. Configure the API URL
# Edit: lib/core/constants/api_constants.dart
# Set baseUrl to your backend URL

# 4. Run on emulator/device
flutter run

# 5. Build debug APK
flutter build apk --debug
```

---

## Deployment Instructions

### Backend → Vercel (Primary)

```bash
cd backend
npm install -g vercel
vercel --prod
```

Set all [environment variables](#environment-variables) in the Vercel dashboard before deploying.

### Backend → Ubuntu VPS (Secondary)

```bash
# Install PM2
npm install -g pm2

# Start server
pm2 start src/server.js --name referral-backend
pm2 save && pm2 startup
```

Use Nginx as a reverse proxy and Certbot for SSL. See [docs/DeploymentGuide.md](docs/DeploymentGuide.md) for detailed instructions.

### Flutter Apps

Build release APKs and distribute via Firebase App Distribution, Google Play internal testing, or direct APK delivery:

```bash
flutter build apk --release
```

---

## Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Database (required)
DATABASE_URL="mysql://user:password@host:4000/database?sslaccept=strict"

# Server
PORT=5000
NODE_ENV=development

# JWT
JWT_SECRET=your_minimum_32_character_secret_here
JWT_EXPIRES_IN=7d

# Cloudinary (required for avatar uploads in production)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Logging
LOG_LEVEL=debug

# App
APP_DOMAIN=your-domain.com
```

> ⚠️ **Never commit `.env` to version control.** The `.gitignore` already excludes it.

See [docs/DeploymentGuide.md](docs/DeploymentGuide.md) for a full variable reference.

---

## API Documentation

Interactive Swagger documentation is available at:

```
http://localhost:5000/api/docs
```

For a complete reference, see [docs/APIReference.md](docs/APIReference.md).

---

## Developer Documentation

| Document | Description |
|----------|-------------|
| [BackendArchitecture.md](docs/BackendArchitecture.md) | Folder structure, services, repositories, middleware flow |
| [DatabaseArchitecture.md](docs/DatabaseArchitecture.md) | Prisma models, relationships, indexes, hierarchy implementation |
| [APIReference.md](docs/APIReference.md) | All endpoints with request/response examples |
| [FlutterArchitecture.md](docs/FlutterArchitecture.md) | Provider pattern, repository pattern, navigation, theme |
| [DeploymentGuide.md](docs/DeploymentGuide.md) | Vercel, TiDB, Cloudinary, VPS deployment |
| [SecurityGuide.md](docs/SecurityGuide.md) | JWT, bcrypt, rate limiting, CORS, audit logging |
| [BusinessLogic.md](docs/BusinessLogic.md) | Registration, referral, approval, point distribution flows |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'feat: add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

CI will automatically run checks on your PR.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
