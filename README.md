# 🚀 Equity Plus (Vridhi / Loop Referral & Video LMS Ecosystem)

[![Backend CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/backend.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/backend.yml)
[![User App CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/user_app.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/user_app.yml)
[![Admin App CI](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/admin_app.yml/badge.svg)](https://github.com/YOUR_USERNAME/ReferralSystem/actions/workflows/admin_app.yml)

> **Equity Plus** is a production-ready, enterprise-grade multi-level network referral platform and Video Learning Management System (LMS). Built with a highly scalable Node.js / Express backend using Prisma ORM with TiDB/MySQL, paired with modern, cross-platform Flutter applications for both end-users and administrators.

---

## 📋 Table of Contents

- [Executive Summary & Architecture](#-executive-summary--architecture)
- [Technology Stack](#-technology-stack)
- [Comprehensive Feature Matrix](#-comprehensive-feature-matrix)
  - [🔐 Authentication & Security](#-authentication--security)
  - [🌲 Multi-Level Referral Hierarchy Engine](#-multi-level-referral-hierarchy-engine)
  - [🎬 Video Learning Management System (LMS)](#-video-learning-management-system-lms)
  - [💳 Monetization, Payments & Cash Flow Engine](#-monetization-payments--cash-flow-engine)
  - [🛡️ Product Access Control & Assignments](#-product-access-control--assignments)
  - [💰 Refund Policy & Watch-Threshold Automation](#-refund-policy--watch-threshold-automation)
  - [🌐 Multilingual Localization & Language Change Requests](#-multilingual-localization--language-change-requests)
  - [🔔 Real-Time Notifications & Push Announcements](#-real-time-notifications--push-announcements)
  - [📊 Administrative Control & Management Suite](#-administrative-control--management-suite)
- [Folder Structure](#-folder-structure)
- [Database Schema & Data Architecture](#-database-schema--data-architecture)
- [Getting Started & Local Setup](#-getting-started--local-setup)
  - [Backend API Setup](#1-backend-api-setup)
  - [User Mobile App Setup](#2-user-mobile-app-setup)
  - [Admin Dashboard App Setup](#3-admin-dashboard-app-setup)
- [Environment Variables Reference](#-environment-variables-reference)
- [API Architecture & Route Map](#-api-architecture--route-map)
- [Deployment Guide](#-deployment-guide)
- [Developer Documentation Index](#-developer-documentation-index)
- [License](#-license)

---

## 🏗️ Executive Summary & Architecture

The **Equity Plus** platform integrates multi-level referral network marketing with high-definition video distribution. It solves key scalability challenges using a **Materialized Path** hierarchy implementation for $O(1)$ ancestor queries, secure multi-provider media streaming (Cloudinary & Cloudflare R2), automated refund eligibility calculation based on video watch metrics, and dual payment support (online via Razorpay and offline via Cash Payment workflow).

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               EQUITY PLUS ECOSYSTEM                             │
├────────────────────────────┬────────────────────────────┬───────────────────────┤
│    User Flutter App        │    Admin Flutter App       │   Node.js Express API │
│   (Android/iOS/Web)        │   (Android/iOS/Web)        │     (v5 Architecture) │
├────────────────────────────┴────────────────────────────┴───────────────────────┤
│                             DATA & ORM STORAGE LAYER                            │
│                 TiDB Cloud / MySQL Database (via Prisma 7 ORM)                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                             INTEGRATED SERVICES                                 │
│  • Cloudinary & Cloudflare R2 (Video & Media Delivery CDN)                       │
│  • Razorpay Payment Gateway (Online Checkout & Verification)                    │
│  • Firebase Cloud Messaging (FCM Push Notifications)                            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Core Architecture Highlights

- **Materialized Path Tree**: Hierarchy stored as string paths (`/root-id/parent-id/user-id`) allowing instant subtree matching without costly recursive SQL joins.
- **Snapshot Integrity**: Upon product purchase, the system captures a frozen snapshot (`UserVideoSnapshot`) of active videos and total duration to accurately evaluate refund eligibility thresholds.
- **Strict Video Access Control**: Only videos explicitly assigned to users via admin rules (`VideoAssignment`) or product access are streamable.
- **Dual Payment Pipeline**: Supports automated digital payments (Razorpay) and manual cash collection verified by administrators in real-time.
- **Soft Deletion & Audit Logging**: User data is soft-deleted (`isDeleted: true`), preserving historical hierarchy nodes while logging complete user snapshots into `DeletedUserLog`.

---

## 💻 Technology Stack

### Backend Stack
| Component | Technology | Description |
|---|---|---|
| **Runtime** | Node.js (v20 LTS) | Enterprise asynchronous JavaScript engine |
| **Framework** | Express.js 5 | High-performance API router |
| **ORM** | Prisma 7 | Type-safe SQL client & schema migration engine |
| **Database** | TiDB Cloud / MySQL | Distributed MySQL-compatible relational database |
| **Authentication** | JWT & Bcrypt | Statetess JSON Web Tokens & salted password hashing |
| **Media Storage** | Cloudinary & Cloudflare R2 | Multi-tier cloud media hosting and streaming |
| **Logging** | Pino Logger | Structured JSON logging with multi-level severity |
| **Security** | Helmet, CORS, Rate Limiter | Protection against XSS, CORS leaks, and brute force |
| **API Docs** | Swagger UI Express | OpenAPI specification & interactive endpoint explorer |

### Frontend / Mobile Apps Stack
| Component | Technology | Description |
|---|---|---|
| **Framework** | Flutter 3.44+ | Cross-platform UI toolkit (iOS, Android, Web, Desktop) |
| **Language** | Dart 3.x | Object-oriented strong-typed language |
| **State Management**| Provider (`ChangeNotifier`) | Reactive and lightweight state propagation |
| **HTTP Client** | `package:http` | REST API communication layer |
| **Video Player** | `video_player` & `chewie` | Native video playback with adaptive bitrate streaming |
| **Local Storage** | `shared_preferences` | Encrypted token and persistent settings cache |
| **QR Code Engine** | `qr_flutter` | Dynamic visual QR code generation |
| **Visualization** | Custom Canvas Painter | Interactive network hierarchy tree viewer |

---

## 🔥 Comprehensive Feature Matrix

### 🔐 Authentication & Security
- **Multi-Role Authentication**: Dedicated authentication pipelines for **USERS** and **ADMINS**.
- **OTP Verification Flow**: One-Time Password support for password resets and verification routines.
- **JWT Session Tokens**: Secure token generation with customizable expiry (`7d`) and payload claim validation.
- **Security Middleware**:
  - Request body sanitization and data format validation.
  - Rate limiting via `express-rate-limit` to prevent denial-of-service and brute-force attacks.
  - CORS security configured with strict origin control.
  - Security headers enforced via `Helmet`.

### 🌲 Multi-Level Referral Hierarchy Engine
- **Materialized Path Engine**: Fast tree traversals using formatted hierarchy paths.
- **Unique Referral Identification**: Automatic generation of unique user referral codes, custom referral URLs, and shareable high-res QR Codes.
- **Interactive Canvas Tree View**:
  - Flutter dynamic canvas rendering of multi-level network hierarchies.
  - Interactive pan, zoom, expand/collapse node states, and real-time user node search.
- **Automated Point & Reward Engine**: Configurable reward point allocation per hierarchy depth level upon successful referral activation.

### 🎬 Video Learning Management System (LMS)
- **Multi-Provider Media Pipeline**: Direct integration with **Cloudinary** and **Cloudflare R2** for efficient media hosting.
- **Chunked Upload Pipeline**: Resumable, chunked uploading for large high-definition video files.
- **Video Versioning & History**: Version control for videos (`VideoVersion`), preserving full update changelogs and historical URLs.
- **Custom Flutter Video Player**:
  - Custom UI controls, playback speed selector, volume sliders, full-screen mode, and seek controls.
  - Dynamic anti-piracy watermark overlay displaying user credentials on screen.
  - Auto-resume playback from last saved timestamp.
- **Comprehensive Analytics & Session Tracking**:
  - Detailed telemetry collection in `PlaybackSession` (tracks watch time, pause counts, seek frequencies, background events, and network interruptions).
  - Per-user video progress calculation (`UserVideoProgress`).

### 💳 Monetization, Payments & Cash Flow Engine
- **Razorpay Payment Gateway**:
  - Seamless online checkout flow.
  - Server-side order creation and cryptographic signature verification (`HMAC-SHA256`).
- **Offline Cash Payment Workflow**:
  - User can submit "Paid by Cash" manual verification requests.
  - Real-time polling mechanism in User App to detect admin verification and update UI immediately.
  - One-click tick-mark verification in Admin dashboard triggering immediate user activation.
- **Transaction History**: Complete log of created, pending, successful, and failed payments.

### 🛡️ Product Access Control & Assignments
- **Product Catalog Management**: Products with custom prices, codes, descriptions, and statuses.
- **User Product Access Lifecycle**: Tracks status states: `PENDING_PAYMENT` ➔ `PENDING_APPROVAL` ➔ `ACTIVE` ➔ `SUSPENDED` / `REVOKED` / `EXPIRED`.
- **Granular Video Assignment**:
  - Explicit assignment of videos to specific users, products, or languages (`VideoAssignment`).
  - Strict server-side filtering: users can ONLY access videos explicitly assigned to them.

### 💰 Refund Policy & Watch-Threshold Automation
- **Automated Snapshot Engine**: Freezes assigned videos and total duration at purchase time (`UserVideoSnapshot`).
- **Dynamic Eligibility Verification**:
  - Automatically calculates total watch percentage against configurable thresholds (e.g., maximum 25% watch limit).
  - Instantly invalidates refund eligibility (`refundEligible: false`) once watch threshold is exceeded.
- **End-to-End Refund Workflow**:
  - User application form requiring bank details, reason, and additional proof.
  - Admin review dashboard to approve or reject with custom administrative remarks.
  - Automatic access revocation (`REVOKED`) upon refund completion.

### 🌐 Multilingual Localization & Language Change Requests
- **Multi-Language Video Catalog**: Organize video content by language (e.g., English, Hindi, Bengali).
- **Formal Language Change Request System**:
  - Users can apply for language reassignment with a written reason.
  - Admin approval workflow with status tracking (`PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`).
  - Automatic update of profile language preferences upon approval.

### 🔔 Real-Time Notifications & Push Announcements
- **In-App Notification Center**: Structured database notifications (`SYSTEM`, `REFERRAL_SIGNUP`, `REFERRAL_APPROVED`, `REWARD`, `PAYMENT`, `REFUND`).
- **Targeted Broadcast Announcements**:
  - Admins can send targeted announcements to **ALL** users, specific **PRODUCT** owners, **LANGUAGE** groups, or **INDIVIDUAL** users.
  - Multi-channel delivery via In-App DB logs and **Firebase Cloud Messaging (FCM)** push notifications.

### 📊 Administrative Control & Management Suite
- **Analytics & Operational Dashboard**: Live counter cards (Total Users, Active Products, Total Revenue, Pending Cash Approvals, Pending Refunds).
- **User Directory & Management**:
  - Search, filter, approve, suspend, or reactivate user profiles.
  - Complete soft-delete support with fallback logging in `DeletedUserLog`.
- **Video Management Hub**: Single dashboard to upload, edit, version, assign, or delete video assets.
- **Refund & Payment Approvals**: Queue view to verify pending cash payments and process refund requests.
- **System Configuration**: Interface to update global parameters (referral points per tier, max refund threshold %, default languages, system rules).

---

## 📁 Folder Structure

```
Equilty-plus-app/
├── .github/
│   └── workflows/
│       ├── backend.yml              # Backend CI/CD Pipeline
│       ├── user_app.yml             # User App CI/CD Pipeline
│       └── admin_app.yml            # Admin App CI/CD Pipeline
│
├── backend/                         # Node.js & Express API Server
│   ├── prisma/
│   │   ├── migrations/              # Database migration SQL files
│   │   ├── schema.prisma            # Master Prisma database schema
│   │   └── seed.js                  # Database seed script
│   └── src/
│       ├── config/                  # Cloudinary, Multer, JWT, R2 configs
│       ├── controllers/             # Request handlers (Thin Controller layer)
│       ├── middleware/               # Auth, Admin, Validation, Rate Limiters
│       ├── repositories/             # Database access layer (Prisma queries)
│       ├── routes/                  # Express API route modules (v1 API)
│       ├── services/                # Core Business Logic services
│       ├── utils/                   # Loggers, helpers, pagination, encryption
│       └── validators/              # Input schemas (Zod / Joi validation)
│
├── user_app/                        # Flutter End-User Mobile Application
│   └── lib/
│       ├── core/                    # API client, theme, storage, constants
│       ├── models/                  # Dart JSON data models
│       ├── providers/               # State Management (ChangeNotifier)
│       ├── repositories/             # HTTP Data repositories
│       └── screens/                 # Feature-rich UI screens
│           ├── auth/                # Login, Register, Forgot Password
│           ├── dashboard/           # User Home, Metrics, Announcements
│           ├── hierarchy/           # Referral Tree Visualizer (Canvas)
│           ├── language_requests/  # Request language swap
│           ├── notifications/       # In-App Notification Center
│           ├── onboarding/          # Profile Setup & Welcome flow
│           ├── payments/            # Checkout (Razorpay & Cash) & History
│           ├── profile/             # User Profile & KYC management
│           ├── referral/            # QR Code, Links & Point Balances
│           ├── refunds/             # Refund submission screen
│           └── videos/              # Video Library & Custom Player
│
├── admin_app/                       # Flutter Admin Operations Dashboard
│   └── lib/
│       ├── core/                    # Shared Network, Theme, Utilities
│       ├── models/                  # Admin Data Models
│       ├── providers/               # Admin State Providers
│       └── screens/                 # Administrative Management Screens
│           ├── analytics/           # Deep-dive analytics dashboards
│           ├── announcements/       # Push Broadcast composer
│           ├── approvals/           # User & Access approval queues
│           ├── hierarchy/           # Master network tree viewer
│           ├── language_requests/  # Review language change requests
│           ├── payments/            # Cash payment approval hub
│           ├── products/            # Product catalog manager
│           ├── refunds/             # Refund audit & processing screen
│           ├── settings/            # System-wide configuration
│           └── videos/              # Video upload hub & assignment matrix
│
├── database/                        # SQL backup scripts & schema dumps
├── docs/                            # Deep technical architecture documentation
└── postman/                         # Postman API Collection
```

---

## 🗄️ Database Schema & Data Architecture

The project relies on 22 strongly-typed Prisma relational models:

```mermaid
erDiagram
    User ||--o| Profile : "has profile"
    User ||--o| HierarchyNode : "positioned in tree"
    User ||--o{ UserProductAccess : "owns product access"
    User ||--o{ UserVideoProgress : "tracks progress"
    User ||--o| UserVideoSnapshot : "locked snapshot"
    User ||--o{ Payment : "initiates payment"
    User ||--o{ RefundRequest : "submits refund"
    User ||--o{ VideoAssignment : "assigned videos"
    
    Product ||--o{ Video : "contains videos"
    Product ||--o{ UserProductAccess : "grants access to"
    
    Video ||--o{ VideoVersion : "tracks versions"
    Video ||--o{ PlaybackSession : "logs telemetry"
    Video ||--o{ SnapshotVideo : "snapshot snapshot"

    Payment ||--o{ UserProductAccess : "fulfills access"
    Payment ||--o{ RefundRequest : "refunded via"
```

### Main Database Tables

1. `User`: Primary user authentication, roles (`USER`/`ADMIN`), referral codes, points balance, active state, soft-delete metadata.
2. `Profile`: Extended KYC fields (First Name, Phone, WhatsApp, State, PAN, Aadhar, Avatar).
3. `HierarchyNode`: Materialized tree node (`path`, `level`, `parentId`).
4. `Product`: Catalog products (`name`, `code`, `price`, `status`).
5. `Video`: Video assets (`videoUrl`, `thumbnailUrl`, `r2ObjectKey`, `duration`, `status`).
6. `VideoVersion`: Historical version snapshots of uploaded video content.
7. `UserProductAccess`: Access state mapping between users and products.
8. `VideoAssignment`: Explicit user-to-video access assignments.
9. `UserVideoSnapshot` & `SnapshotVideo`: Frozen state of videos upon purchase for refund integrity.
10. `Payment`: Payment records for online (Razorpay) and offline (Cash) transactions.
11. `RefundRequest`: Form submissions for payment refunds with status tracking.
12. `LanguageChangeRequest`: User language change applications and audit statuses.
13. `Announcement` & `Notification`: Messaging and push notification payloads.
14. `SystemSettings`: Global runtime parameters (e.g., dynamic points, refund thresholds).
15. `AuditLog` & `DeletedUserLog`: Full security action logs and backups of soft-deleted users.

---

## 🛠️ Getting Started & Local Setup

### Prerequisites
- **Node.js**: v20.x LTS or higher
- **npm**: v9.x or higher
- **Flutter SDK**: v3.44.x (stable channel)
- **Database**: Access to MySQL 8.0+ or TiDB Cloud instance
- **Cloudinary / Cloudflare R2 Account** (Optional for local media uploads)

---

### 1. Backend API Setup

```bash
# Step 1: Navigate to backend directory
cd backend

# Step 2: Install project dependencies
npm install

# Step 3: Configure Environment Variables
cp .env.example .env
# Edit .env with your MySQL connection string and JWT secret (see section below)

# Step 4: Run Prisma Database Migrations
npx prisma db push

# Step 5: Generate Prisma Client
npx prisma generate

# Step 6: (Optional) Seed Initial Database Data
node prisma/seed.js

# Step 7: Start Development Server
npm run dev
```

- **Backend Base URL**: `http://localhost:5000`
- **Swagger Documentation**: `http://localhost:5000/api/docs`
- **API Health Check**: `http://localhost:5000/api/v1/health`

---

### 2. User Mobile App Setup

```bash
# Step 1: Navigate to user_app directory
cd user_app

# Step 2: Fetch Flutter dependencies
flutter pub get

# Step 3: Configure API Endpoint
# Open: lib/core/constants/api_constants.dart
# Set baseUrl to your backend address:
# - Android Emulator: http://10.0.2.2:5000/api/v1
# - Physical Device / iOS: http://<YOUR_LOCAL_IP>:5000/api/v1

# Step 4: Run on attached device or emulator
flutter run

# Step 5: Build Debug APK
flutter build apk --debug
```

---

### 3. Admin Dashboard App Setup

```bash
# Step 1: Navigate to admin_app directory
cd admin_app

# Step 2: Fetch dependencies
flutter pub get

# Step 3: Configure API Endpoint
# Open: lib/core/constants/api_constants.dart
# Set baseUrl to your backend address

# Step 4: Launch Admin Dashboard
flutter run

# Step 5: Build Release Web / Android APK
flutter build apk --release
```

---

## 🔑 Environment Variables Reference

Create a `.env` file in the `backend/` root directory:

```env
# ==========================================
# DATABASE CONFIGURATION
# ==========================================
DATABASE_URL="mysql://username:password@localhost:3306/equity_plus_db?sslaccept=strict"

# ==========================================
# APPLICATION & SERVER CONFIGURATION
# ==========================================
PORT=5000
NODE_ENV=development
APP_DOMAIN=localhost:5000
LOG_LEVEL=debug

# ==========================================
# AUTHENTICATION & SECURITY
# ==========================================
JWT_SECRET=super_secret_jwt_key_must_be_at_least_32_characters_long
JWT_EXPIRES_IN=7d

# ==========================================
# CLOUDINARY (MEDIA STORAGE)
# ==========================================
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# ==========================================
# CLOUDFLARE R2 / AWS S3 (VIDEO CDN)
# ==========================================
CLOUDFLARE_R2_ACCOUNT_ID=your_r2_account_id
CLOUDFLARE_R2_ACCESS_KEY_ID=your_r2_access_key
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_r2_secret_key
CLOUDFLARE_R2_BUCKET_NAME=your_r2_bucket_name
CLOUDFLARE_R2_CUSTOM_DOMAIN=https://media.yourdomain.com

# ==========================================
# RAZORPAY PAYMENT GATEWAY
# ==========================================
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

---

## 📡 API Architecture & Route Map

All API endpoints are versioned under `/api/v1/`:

| Namespace | Base Route | Key Operations |
|---|---|---|
| **Auth** | `/api/v1/auth` | User registration, login, admin login, OTP requests, logout |
| **User** | `/api/v1/users` | Profile retrieval, user management, status toggles |
| **Profile** | `/api/v1/profile` | Update profile, upload avatar, KYC verification |
| **Hierarchy**| `/api/v1/hierarchy` | Get tree nodes, calculate downline, visualizer payload |
| **Referrals** | `/api/v1/referrals` | Referral list, stats, link & QR code generation |
| **Products** | `/api/v1/products` | Product CRUD, catalog listing, assignment |
| **Videos** | `/api/v1/videos` | Video CRUD, stream URLs, status management |
| **Versions** | `/api/v1/video-versions` | Video version history, rollback, changelog |
| **Assign** | `/api/v1/video-assignments`| User video assignments, grant/revoke permissions |
| **Uploads** | `/api/v1/uploads` | Chunked file uploads to Cloudinary/R2 |
| **Playback** | `/api/v1/playback-sessions`| Heartbeat tracking, telemetry session logs |
| **Analytics**| `/api/v1/video-analytics`| System watch metrics, completion stats |
| **Payments** | `/api/v1/payments` | Razorpay order creation, cash payment submission, verification |
| **Refunds** | `/api/v1/refunds` | Refund request submission, eligibility check, admin approval |
| **Languages**| `/api/v1/languages` | Language CRUD, default settings |
| **LangReq** | `/api/v1/language-change-requests` | Request language swap, administrative approvals |
| **Announce** | `/api/v1/announcements`| Create broadcast announcements, target groups |
| **Notifs** | `/api/v1/notifications` | In-app notifications list, mark as read |
| **Settings** | `/api/v1/settings` | System-wide runtime parameters |
| **Admin** | `/api/v1/admin` | Operational metrics, overall dashboard statistics |
| **Search** | `/api/v1/search` | Global entity search (users, videos, products) |

---

## 🚀 Deployment Guide

### Option 1: Vercel (Backend Serverless)

The backend Express app includes built-in compatibility for Vercel serverless functions:

```bash
cd backend
npm install -g vercel
vercel --prod
```
*Make sure to enter all environment variables in the Vercel Dashboard Settings.*

### Option 2: Linux VPS (PM2 & Nginx)

```bash
# Step 1: Install PM2 Process Manager
npm install -g pm2

# Step 2: Start Application
cd backend
pm2 start src/server.js --name equity-backend

# Step 3: Save PM2 State for automatic reboot recovery
pm2 save
pm2 startup
```

Configure **Nginx** as a reverse proxy targeting `http://127.0.0.1:5000` with **Certbot** for automatic SSL renewal.

### Option 3: Flutter Mobile Builds

```bash
# Build Android Production Release Bundle
flutter build appbundle --release

# Build Android Standalone APK
flutter build apk --release
```

---

## 📚 Developer Documentation Index

Detailed architectural specs and design documents are located in the [`/docs`](docs/) directory:

- 📐 [Backend Architecture Guide](docs/BackendArchitecture.md) — Multi-tier layer patterns, repositories & services.
- 🗄️ [Database Architecture Guide](docs/DatabaseArchitecture.md) — Entity relationships, indexing strategies & tree pathing.
- 📱 [Flutter Architecture Guide](docs/FlutterArchitecture.md) — State management, providers & routing setup.
- 💳 [Payment Architecture Guide](docs/PaymentArchitecture.md) — Razorpay integration & cash payment verification flow.
- 💰 [Refund Architecture Guide](docs/RefundArchitecture.md) — Watch thresholds, snapshots & refund lifecycle.
- 🎥 [Video Learning Architecture](docs/VideoLearningArchitecture.md) — Media pipelines, chunked uploads & playback telemetry.
- 🔐 [Security & Compliance Guide](docs/SecurityGuide.md) — JWT auth, password encryption & rate limiting.
- 🌐 [Deployment Guide](docs/DeploymentGuide.md) — Production hosting on Vercel, VPS & Cloudflare.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for complete licensing terms.
