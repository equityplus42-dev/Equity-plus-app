# Testing Guidelines

This document explains how to run automated unit tests and perform manual verification.

## 1. Automated Integration Tests
Automated tests run against the database to verify authentication routes, profile persistence, and multi-level rewards logic.

To run tests:
1. Ensure your PostgreSQL/MySQL local instance is running and matches the `DATABASE_URL` in `.env`.
2. Generate the Prisma Client and run migrations:
   ```bash
   cd backend
   npx prisma db push
   ```
3. Run the test suite:
   ```bash
   node tests/auth.test.js
   node tests/hierarchy.test.js
   node tests/user.test.js
   ```

## 2. Manual Verification Checklist
- **Registration**: Register a user with code `ADMINREF`. Verify in database that their `referrerId` points to the admin's ID, their level is `1`, and their path is `/admin-uuid/user-uuid`.
- **Automatic Points**: Set `require_admin_approval` setting in DB to `false`. Register another user using the first user's code. Verify points are added instantly: Level 1 (inviter) gets 100 points, Level 2 (admin) gets 50 points.
- **Manual Approvals**: Set `require_admin_approval` in DB to `true`. Sign up. Verify a row appears in the admin approvals page, and points are only added after clicking **Approve**.
- **Avatars**: Change your avatar image in the profile screen. Verify it uploads to Cloudinary or falls back to a placeholder avatar.
- **QR Codes**: Open the QR code modal on the dashboard. Scan with a phone to ensure it decodes to a valid URL containing the referral code.
