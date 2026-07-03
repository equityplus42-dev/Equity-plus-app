# Deployment Guide

This guide outlines setup procedures for hosting the Express.js server on **Vercel** and connecting it to a **TiDB** cluster.

## 1. Environment Configurations
All variables must be defined inside `.env` or in your hosting provider's config console. They are resolved via `backend/src/config/env.js`:
- `PORT` (Default: 5000)
- `NODE_ENV` (`development` or `production`)
- `DATABASE_URL` — MySQL connection string (e.g. `mysql://user:pass@host:port/dbname`)
- `JWT_SECRET` — Cryptographic key for authorization tokens
- `JWT_EXPIRES_IN` — Token expiry window (e.g. `7d`)
- `APP_DOMAIN` — Your server base domain (used to format referral URLs, e.g. `referral-system.com`)
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` — Image assets uploads configuration parameters.

## 2. TiDB Cloud Cluster Setup
1. Log in to [TiDB Cloud Console](https://tidbcloud.com/).
2. Create a Serverless Cluster (Free tier).
3. Open the cluster connection details panel.
4. Copy the connection string format for **MySQL**.
5. Paste the connection string into the backend `.env` file under `DATABASE_URL`.

## 3. Database Initialization
Ensure your schema and client are compiled:
```bash
cd backend
npx prisma generate
npx prisma db push
```

## 4. Vercel Backend Deployment
Deploy the backend on Vercel:
1. Navigate to the backend folder: `cd backend`.
2. Configure environmental variables inside the Vercel dashboard.
3. Deploy to production: `vercel --prod`.

## 5. Flutter Client Compilations
Configure base URL constants in `lib/core/constants/api_constants.dart`:
- Set `baseUrl` to `https://your-vercel-domain.vercel.app/api/v1`.
- Build the APK:
  ```bash
  flutter build apk --release
  ```
