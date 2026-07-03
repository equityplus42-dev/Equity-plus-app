# Database Specifications

## Relational Model Schema

The database consists of 6 primary tables optimized for TiDB Cloud.

### 1. User
Stores user accounts and authentication credentials.
- `id` (VARCHAR(36), PK): UUID.
- `email` (VARCHAR(191), UNIQUE): Email address.
- `password` (VARCHAR(191)): Hashed password.
- `role` (VARCHAR(191)): `USER` or `ADMIN`.
- `referralCode` (VARCHAR(191), UNIQUE): Unique 8-character code.
- `referralUrl` (VARCHAR(255)): Permanent referral link.
- `qrCode` (TEXT): Base64 string of the referral QR Code.
- `referrerId` (VARCHAR(36), FK, Indexed): Direct referrer.
- `points` (INT): Active points reward balance.
- `isApproved` (BOOLEAN): User approval switch.

### 2. Profile
Extended biographical metadata for users.
- `id` (VARCHAR(36), PK): UUID.
- `userId` (VARCHAR(36), UNIQUE, FK): Links to User table.
- `firstName` (VARCHAR(191)): First name.
- `lastName` (VARCHAR(191)): Last name.
- `phoneNumber` (VARCHAR(191), Indexed): Mobile number (search indexed).
- `avatarUrl` (VARCHAR(191)): Profile picture.
- `bio` (TEXT): Biographical text.

### 3. Referral
Tracks signup conversions and reward levels.
- `id` (VARCHAR(36), PK): UUID.
- `referrerId` (VARCHAR(36), FK, Indexed): Inviter user.
- `refereeId` (VARCHAR(36), UNIQUE, FK): New user registered.
- `status` (VARCHAR(191), Indexed): `PENDING`, `APPROVED`, or `REJECTED`.
- `points` (INT): Reward points allocated for Level 1.

### 4. HierarchyNode
Optimized materialized path for fast recursive downline tree traversals.
- `id` (VARCHAR(36), PK): UUID.
- `userId` (VARCHAR(36), UNIQUE, FK): Links to User.
- `parentId` (VARCHAR(36), Indexed): Direct parent user.
- `path` (VARCHAR(511), Indexed): Materialized path, e.g. `/root-id/parent-id/user-id`.
- `level` (INT): Node depth in tree (0-indexed).

### 5. Notification
In-app alerts log.
- `id` (VARCHAR(36), PK): UUID.
- `userId` (VARCHAR(36), FK, Indexed): Recipient user.
- `title` (VARCHAR(191)): Notification title.
- `message` (TEXT): Notification body.
- `isRead` (BOOLEAN): Read flag.
- `type` (VARCHAR(191)): System, Signup, or Reward.
- `createdAt` (DATETIME, Indexed): Creation timestamp.

### 6. SystemSettings
System settings key-value store.
- `id` (VARCHAR(36), PK): UUID.
- `key` (VARCHAR(191), UNIQUE): Configuration key.
- `value` (TEXT): Configuration value.
- `description` (TEXT): Configuration details.
