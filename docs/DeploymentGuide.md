# Deployment Guide

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Variables Reference](#environment-variables-reference)
3. [Local Development](#local-development)
4. [TiDB Cloud Configuration](#tidb-cloud-configuration)
5. [Cloudinary Configuration](#cloudinary-configuration)
6. [Vercel Deployment (Primary)](#vercel-deployment)
7. [Future Ubuntu VPS Deployment](#future-ubuntu-vps-deployment)
8. [Flutter App Configuration](#flutter-app-configuration)
9. [Health Check & Smoke Test](#health-check--smoke-test)

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Node.js | ≥ 18.x LTS | Backend runtime |
| npm | ≥ 9.x | Package manager |
| Flutter | 3.44 | Mobile app builds |
| Dart SDK | ≥ 3.0 | Included with Flutter |
| Prisma CLI | ≥ 7.x | `npx prisma` |
| Git | any | Version control |

---

## Environment Variables Reference

Create a `.env` file in `backend/` (never commit this file — it is in `.gitignore`).

```env
# ─── Database ────────────────────────────────────────────────────────────────
DATABASE_URL="mysql://USER:PASSWORD@HOST:PORT/DATABASE?ssl-ca=/path/to/cert"

# ─── Server ──────────────────────────────────────────────────────────────────
PORT=5000
NODE_ENV=development

# ─── JWT ─────────────────────────────────────────────────────────────────────
JWT_SECRET=your_super_secret_jwt_key_minimum_32_chars
JWT_EXPIRES_IN=7d

# ─── Cloudinary ───────────────────────────────────────────────────────────────
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=your_api_secret

# ─── Logging ─────────────────────────────────────────────────────────────────
LOG_LEVEL=debug

# ─── App ─────────────────────────────────────────────────────────────────────
APP_DOMAIN=localhost:3000
```

### Production vs Development Variable Checklist

| Variable | Dev | Production |
|----------|-----|-----------|
| `DATABASE_URL` | Local or TiDB dev cluster | TiDB Cloud production cluster |
| `NODE_ENV` | `development` | `production` |
| `JWT_SECRET` | Any string | Strong random secret (≥ 64 chars) |
| `LOG_LEVEL` | `debug` | `info` or `warn` |
| `APP_DOMAIN` | `localhost:3000` | `your-production-domain.com` |
| `CLOUDINARY_*` | Optional (mock URLs used if absent) | Required for real uploads |

> **Warning**: Never commit `.env` to version control. Use Vercel Dashboard or server environment management for production secrets.

---

## Local Development

### 1. Clone and Install

```bash
git clone https://github.com/your-org/ReferralSystem.git
cd ReferralSystem/backend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your local values
```

### 3. Synchronize Database Schema

```bash
# Push schema changes to TiDB/MySQL (no migration files)
npx prisma db push

# Regenerate Prisma client after any schema change
npx prisma generate
```

> **Note**: `npx prisma migrate` is **not** used with TiDB Cloud. Always use `npx prisma db push` followed by `npx prisma generate`.

### 4. Seed the Database (Optional)

```bash
node prisma/seed.js
```

This creates the default admin account and initial system settings.

### 5. Start the Development Server

```bash
npm run dev
```

The server starts at `http://localhost:5000` with hot-reload via `nodemon`.

### 6. Access API Documentation

Open `http://localhost:5000/api/docs` in your browser for the interactive Swagger UI.

### 7. Verify Health

```bash
curl http://localhost:5000/api/v1/health
```

Expected response:
```json
{ "success": true, "message": "Server running", "version": "1.0.0", "database": "Connected" }
```

---

## TiDB Cloud Configuration

TiDB Cloud is the primary database provider. It is MySQL-compatible and works seamlessly with Prisma.

### Step 1: Create a TiDB Serverless Cluster

1. Go to [tidbcloud.com](https://tidbcloud.com) and sign in.
2. Create a **Serverless** cluster (free tier available).
3. Set a root password.

### Step 2: Get the Connection String

1. In the TiDB Cloud console, go to **Connect**.
2. Select **Prisma** as the connection type.
3. Copy the connection string. It looks like:
   ```
   mysql://root:PASSWORD@HOST.tidbcloud.com:4000/DATABASE?sslaccept=strict
   ```

### Step 3: Set DATABASE_URL

Paste the connection string into your `.env`:
```env
DATABASE_URL="mysql://root:PASSWORD@HOST.tidbcloud.com:4000/DATABASE?sslaccept=strict"
```

### Step 4: Apply Schema

```bash
cd backend
npx prisma db push
npx prisma generate
```

### TiDB-Specific Notes

- TiDB uses port `4000` by default (not MySQL's `3306`).
- SSL is required — the `?sslaccept=strict` parameter handles this.
- `prisma.prisma` uses `provider = "mysql"` — this is correct for TiDB.
- `@@index` and `@unique` annotations work identically to standard MySQL.
- Do **not** use `npx prisma migrate` — use `db push` exclusively.

---

## Cloudinary Configuration

Cloudinary stores all user-uploaded profile images.

### Step 1: Create a Free Account

1. Go to [cloudinary.com](https://cloudinary.com) and sign up.
2. Navigate to **Dashboard**.
3. Note your **Cloud Name**, **API Key**, and **API Secret**.

### Step 2: Configure Environment Variables

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=your_api_secret
```

### Step 3: (Optional) Create an Upload Preset

For additional control, create an unsigned upload preset in the Cloudinary Media Library settings. The current implementation uses the SDK directly with signed uploads.

### How It Works

```
Flutter App
    │ multipart/form-data POST /api/v1/profile/avatar
    ▼
Multer (memoryStorage)
    │ stores file in Buffer — no disk write
    ▼
CloudinaryService.uploadImage(buffer, 'avatars')
    │ streams Buffer → Cloudinary uploader
    ▼
Cloudinary CDN
    │ returns secure_url
    ▼
Profile.avatarUrl updated in TiDB
    │
    ▼
secure_url returned to Flutter
```

**No images are ever stored on the server filesystem.**

If `CLOUDINARY_*` environment variables are absent, `cloudinary.service.js` falls back to returning random Unsplash placeholder URLs — allowing development without a Cloudinary account.

---

## Vercel Deployment

Vercel is the primary deployment target for the Node.js backend.

### Step 1: Install Vercel CLI

```bash
npm install -g vercel
```

### Step 2: Create `vercel.json` in `backend/`

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/server.js"
    }
  ]
}
```

### Step 3: Set Environment Variables on Vercel

In the Vercel dashboard → Project → Settings → Environment Variables, add:

- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `NODE_ENV` = `production`
- `APP_DOMAIN` = `your-vercel-domain.vercel.app` (or custom domain)

### Step 4: Deploy

```bash
cd backend
vercel --prod
```

### Step 5: Post-Deploy

After the first successful deployment:

1. Run a schema push from your local machine (pointed at the production TiDB):
   ```bash
   DATABASE_URL="production_url" npx prisma db push
   DATABASE_URL="production_url" npx prisma generate
   ```

2. Run the seeder if needed:
   ```bash
   DATABASE_URL="production_url" node prisma/seed.js
   ```

3. Verify with:
   ```bash
   curl https://your-app.vercel.app/api/v1/health
   ```

### Vercel Limitations

- Vercel runs serverless functions — each request may spin up a cold start.
- Prisma's `PrismaClient` singleton is instantiated per function invocation in Vercel's serverless environment. This is handled correctly by the singleton pattern in `config/database.js`.
- The `LOG_LEVEL` should be set to `info` — Vercel captures stdout/stderr logs.

---

## Future Ubuntu VPS Deployment

When migrating to a VPS (e.g., DigitalOcean Droplet, Linode, AWS EC2):

### Step 1: Provision the Server

```bash
# Ubuntu 22.04 LTS recommended
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential
```

### Step 2: Install Node.js via nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

### Step 3: Install PM2 (Process Manager)

```bash
npm install -g pm2
```

### Step 4: Clone and Configure

```bash
git clone https://github.com/your-org/ReferralSystem.git /var/www/referral
cd /var/www/referral/backend
npm install --production
cp .env.example .env
# Edit .env with production values
```

### Step 5: Apply Schema

```bash
npx prisma generate
npx prisma db push
node prisma/seed.js
```

### Step 6: Start with PM2

```bash
pm2 start src/server.js --name referral-backend
pm2 save
pm2 startup
```

### Step 7: Nginx Reverse Proxy

Install Nginx and create a configuration:

```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Step 8: SSL with Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.your-domain.com
```

### Differences from Vercel

| Aspect | Vercel | VPS |
|--------|--------|-----|
| Scaling | Automatic | Manual (PM2 cluster mode) |
| Cold starts | Yes | No (persistent process) |
| SSL | Automatic | Manual via Certbot |
| Logs | Dashboard | `pm2 logs` or journald |
| Cost | Pay-per-use | Fixed monthly |
| Deploy | `vercel --prod` | `git pull && pm2 restart` |

---

## Flutter App Configuration

### Set the API Base URL

Edit `user_app/lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Development
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  
  // Production
  // static const String baseUrl = 'https://your-api.vercel.app/api/v1';
  
  static const String login = '/auth/login';
  // ... other endpoints
}
```

> **Note**: `10.0.2.2` is Android emulator's loopback address to the host machine. Use `localhost` for iOS Simulator.

### Build for Release

```bash
# User App APK
cd user_app
flutter build apk --release

# Admin App APK
cd admin_app
flutter build apk --release
```

---

## Health Check & Smoke Test

After any deployment, run this sequence to verify the system:

```bash
BASE="https://your-domain.com/api/v1"

# 1. Health check
curl "$BASE/health"

# 2. Register a test user
curl -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@smoke.com","password":"Test1234!"}'

# 3. Login
TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@smoke.com","password":"Test1234!"}' | jq -r '.data.token')

# 4. Get profile
curl "$BASE/users/profile" -H "Authorization: Bearer $TOKEN"

# 5. Get settings
curl "$BASE/settings" -H "Authorization: Bearer $TOKEN"
```

All responses should have `"success": true`.
