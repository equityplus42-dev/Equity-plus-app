# Database Architecture

> **Database Engine**: TiDB Cloud (MySQL-compatible)
> **ORM**: Prisma v7.x
> **Schema file**: `backend/prisma/schema.prisma`

---

## Table of Contents

1. [Overview](#overview)
2. [Model Reference](#model-reference)
   - [User](#user-model)
   - [Profile](#profile-model)
   - [Referral](#referral-model)
   - [HierarchyNode](#hierarchynode-model)
   - [Notification](#notification-model)
   - [SystemSettings](#systemsettings-model)
   - [AuditLog](#auditlog-model)
3. [Relationships](#relationships)
4. [Indexes](#indexes)
5. [Hierarchy Implementation](#hierarchy-implementation)
6. [Soft Delete](#soft-delete)
7. [Audit Logging](#audit-logging)
8. [Schema Diagram](#schema-diagram)

---

## Overview

The database schema is designed around a **multi-level referral network**. Every registered user:

- Has a unique referral code and URL.
- Can optionally be referred by another user.
- Has a node in the `HierarchyNode` table representing their position in the tree.
- May accumulate points when their referrals are approved up to a configurable depth.
- Can never be permanently deleted (soft delete).
- Has all critical actions recorded in the `AuditLog` table.

---

## Model Reference

### User Model

The central entity of the system.

```prisma
model User {
  id           String    @id @default(uuid())
  email        String    @unique
  password     String
  role         String    @default("USER")   // USER | ADMIN
  referralCode String    @unique
  referralUrl  String?   @db.VarChar(255)
  qrCode       String?   @db.Text
  referrerId   String?
  points       Int       @default(0)
  isApproved   Boolean   @default(true)
  isActive     Boolean   @default(true)
  isDeleted    Boolean   @default(false)
  deletedAt    DateTime?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  ...
  @@index([referrerId])
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key, auto-generated |
| `email` | String (unique) | Login credential |
| `password` | String | bcrypt hash; never returned in API responses |
| `role` | Enum-string | `USER` or `ADMIN` |
| `referralCode` | String (unique) | 8-character alphanumeric code generated at registration |
| `referralUrl` | String | Full URL: `https://{APP_DOMAIN}/ref/{referralCode}` |
| `qrCode` | Text | Base64-encoded PNG of the referral QR code |
| `referrerId` | FK → User | ID of the user who referred this user (nullable) |
| `points` | Int | Accumulated reward points balance |
| `isApproved` | Boolean | Admin can suspend (`false`) or approve (`true`) |
| `isActive` | Boolean | Set to `false` on soft delete |
| `isDeleted` | Boolean | Soft-delete flag — `true` means logically deleted |
| `deletedAt` | DateTime | Timestamp of soft deletion |

---

### Profile Model

One-to-one extension of `User` holding personal information.

```prisma
model Profile {
  id          String   @id @default(uuid())
  userId      String   @unique
  firstName   String?
  lastName    String?
  phoneNumber String?
  avatarUrl   String?
  bio         String?  @db.Text
  ...
  @@index([phoneNumber])
}
```

| Field | Description |
|-------|-------------|
| `userId` | FK → `User.id` (unique — one profile per user) |
| `avatarUrl` | Cloudinary secure URL; never a local filesystem path |
| `bio` | Optional free-text field stored as `TEXT` |

The profile is created automatically alongside the `User` record during registration.

---

### Referral Model

Records the direct referral relationship between two users.

```prisma
model Referral {
  id         String   @id @default(uuid())
  referrerId String
  refereeId  String   @unique
  status     String   @default("PENDING")  // PENDING | APPROVED | REJECTED
  points     Int      @default(0)
  ...
  @@index([referrerId])
  @@index([status])
  @@index([referrerId, status])
}
```

| Field | Description |
|-------|-------------|
| `referrerId` | FK → `User.id` — The user who shared the referral link |
| `refereeId` | FK → `User.id` (unique) — The user who joined via the link. A user can only be referred once. |
| `status` | `PENDING` (awaiting admin review), `APPROVED` (rewards granted), `REJECTED` (no rewards) |
| `points` | The direct (L1) points value assigned at creation time |

**Important**: The `refereeId` is `@unique`, meaning each user can have **at most one** `Referral` record as a referee — you cannot be referred by two people.

---

### HierarchyNode Model

Implements the **Materialized Path** pattern for efficient multi-level tree traversal.

```prisma
model HierarchyNode {
  id       String @id @default(uuid())
  userId   String @unique
  parentId String?
  path     String @db.VarChar(511)
  level    Int
  ...
  @@index([path])
  @@index([parentId])
}
```

| Field | Description |
|-------|-------------|
| `userId` | FK → `User.id` (unique — one node per user) |
| `parentId` | FK → the direct referrer's `userId` in the hierarchy |
| `path` | Materialized path string — see [Hierarchy Implementation](#hierarchy-implementation) |
| `level` | Depth in the tree. Root users (no referrer) have `level = 0` |

---

### Notification Model

Stores in-app notifications for each user.

```prisma
model Notification {
  id        String   @id @default(uuid())
  userId    String
  title     String
  message   String   @db.Text
  isRead    Boolean  @default(false)
  type      String   @default("SYSTEM")
  createdAt DateTime @default(now())
  ...
  @@index([userId])
  @@index([userId, isRead])
  @@index([userId, createdAt])
}
```

| Notification Type | Trigger |
|------------------|---------|
| `REFERRAL_SIGNUP` | Someone signs up using this user's referral code |
| `REFERRAL_APPROVED` | Admin approves a referral — direct referrer gets points notification |
| `REFERRAL_REJECTED` | Admin rejects a referral |
| `SYSTEM` | Indirect reward notifications (Level 2, Level 3 in hierarchy) |

Notifications are always created in the database. A Firebase push notification is attempted concurrently — if it fails, it is logged but does not affect the DB write.

---

### SystemSettings Model

Key-value store for admin-configurable system parameters.

```prisma
model SystemSettings {
  id          String   @id @default(uuid())
  key         String   @unique
  value       String   @db.Text
  description String?  @db.Text
  ...
}
```

| Setting Key | Default | Description |
|-------------|---------|-------------|
| `points_level_1` | `100` | Points awarded to the direct referrer (L1) |
| `points_level_2` | `50` | Points awarded two levels up (L2) |
| `points_level_3` | `25` | Points awarded three levels up (L3) |
| `max_hierarchy_depth` | `3` | Maximum levels to distribute rewards |
| `require_admin_approval` | `false` | If `true`, new referrals start as `PENDING` |

The system always falls back to coded defaults if a key is not in the database.

---

### AuditLog Model

Immutable log of all critical user and admin actions.

```prisma
model AuditLog {
  id        String   @id @default(uuid())
  userId    String?
  action    String
  ipAddress String?
  userAgent String?
  details   String?  @db.Text
  createdAt DateTime @default(now())
  ...
  @@index([userId])
  @@index([action])
  @@index([createdAt])
}
```

| Field | Description |
|-------|-------------|
| `userId` | Nullable FK → `User`. Nullable because the user could be deleted (`SetNull`). |
| `action` | The action string (see [Audit Logging](#audit-logging)) |
| `ipAddress` | Client IP extracted from the Express request |
| `userAgent` | `User-Agent` header string |
| `details` | JSON-stringified context data (e.g., `{ email, referralId, adminId }`) |

---

## Relationships

```
User (1) ─────────────── (1) Profile
User (1) ─────────────── (0..1) Referral [as referee]
User (1) ─────────────── (*) Referral [as referrer]
User (1) ─────────────── (1) HierarchyNode
User (1) ─────────────── (*) Notification
User (1) ─────────────── (*) AuditLog
User (0..1) ─────────────── (*) User [self-referential: referrals]
```

### Self-referential User Relationship
```prisma
referrer  User?  @relation("UserReferrals", fields: [referrerId], references: [id], onDelete: SetNull)
referrals User[] @relation("UserReferrals")
```
A user can **refer many** people (`referrals[]`) but can only **be referred by one** user (`referrer`). If a referrer is deleted, `referrerId` is set to `NULL` (not cascaded).

### Cascade Behavior

| Parent Deleted | Child Behavior |
|----------------|---------------|
| `User` deleted | `Profile` → **Cascade delete** |
| `User` deleted | `Referral` (both roles) → **Cascade delete** |
| `User` deleted | `HierarchyNode` → **Cascade delete** |
| `User` deleted | `Notification` → **Cascade delete** |
| `User` deleted | `AuditLog.userId` → **Set NULL** (log is preserved) |
| `User` deleted | `User.referrerId` → **Set NULL** (referred users kept) |

> **Note**: Soft delete (`isDeleted: true`) is used in practice, so Prisma cascades are rarely triggered.

---

## Indexes

Indexes are carefully chosen for the query patterns used in the application:

| Model | Index | Query Pattern |
|-------|-------|--------------|
| `User` | `referrerId` | Finding all direct referrals of a user |
| `Profile` | `phoneNumber` | Phone-based profile lookup |
| `Referral` | `referrerId` | Admin pending list per referrer |
| `Referral` | `status` | Filtering all pending/approved referrals |
| `Referral` | `(referrerId, status)` | Composite: referrer's pending referrals |
| `HierarchyNode` | `path` | **Prefix scan** for descendant queries: `path LIKE '/root/.../userId/%'` |
| `HierarchyNode` | `parentId` | Direct children lookup |
| `Notification` | `userId` | Fetching all notifications for a user |
| `Notification` | `(userId, isRead)` | Unread notification badge count |
| `Notification` | `(userId, createdAt)` | Sorted notification list |
| `AuditLog` | `userId` | User's action history |
| `AuditLog` | `action` | Filtering by action type |
| `AuditLog` | `createdAt` | Time-range audit queries |

---

## Hierarchy Implementation

The hierarchy uses the **Materialized Path** (also called "Path Enumeration") pattern. Each node stores the full path from the root to itself as a string.

### Path Format
```
/userId_A
/userId_A/userId_B
/userId_A/userId_B/userId_C
```

- The root user has path `/userId_A`.
- A direct referral of A has path `/userId_A/userId_B`.
- B's direct referral has path `/userId_A/userId_B/userId_C`.

### Building a Path
Implemented in `utils/hierarchyHelper.js` `buildPath()`:
```js
function buildPath(parentPath, userId) {
  if (!parentPath) return `/${userId}`;  // Root node
  return `${parentPath}/${userId}`;
}
```

### Finding Descendants
Using a SQL `LIKE` prefix scan:
```js
path: { startsWith: `${userPath}/` }
```
This retrieves **all descendants** at any depth in a single query — no recursion required. Optionally filtered by `level <= maxLevel` for depth limits.

### Extracting Ancestors
```js
function getAncestorsFromPath(path) {
  const parts = path.split('/').filter(Boolean);
  parts.pop();  // Remove the user themselves
  return parts; // [root, ..., direct_parent]
}
```
Reversing this gives `[direct_parent, ..., root]` for walking up the chain during point distribution.

### Point Distribution Walk
```
New user C joins via B (who was referred by A)
C's path: /A/B/C

Ancestors (excluding C): [A, B]
Reversed: [B, A]

Level 1 (B) → gets points_level_1 (100 pts)
Level 2 (A) → gets points_level_2 (50 pts)
```

---

## Soft Delete

Soft delete prevents permanent data loss for user accounts. Hard deletes are never performed on `User` records.

### Fields Involved

| Field | Behavior on Deletion |
|-------|---------------------|
| `isDeleted` | Set to `true` |
| `isActive` | Set to `false` |
| `deletedAt` | Set to `DateTime.now()` |

### Repository Behavior (`user.repository.js`)

**Delete** (`deleteUser(id)`):
```js
prisma.user.update({
  where: { id },
  data: { isDeleted: true, isActive: false, deletedAt: new Date() }
})
```

**List** (`findAll()`):
```js
const where = { isDeleted: false, ... }
```

**Login** (`auth.service.js`):
```js
if (!user || user.isDeleted) {
  throw new Error('Invalid email or password');
}
```
Soft-deleted users cannot log in. The error message is deliberately vague to avoid user enumeration.

---

## Audit Logging

The `AuditLog` table records all security-relevant and admin actions.

### Logged Actions

| Action | Trigger |
|--------|---------|
| `REGISTER` | New user registration |
| `LOGIN` | Successful user login |
| `PROFILE_UPDATE` | User updates profile fields |
| `AVATAR_UPDATE` | User uploads a new avatar |
| `USER_DELETE` | Admin soft-deletes a user |
| `USER_APPROVE` | Admin approves a user account |
| `USER_SUSPEND` | Admin suspends a user account |
| `REFERRAL_APPROVAL` | Admin approves a referral |
| `REFERRAL_REJECTION` | Admin rejects a referral |
| `ADMIN_SETTINGS_UPDATE` | Admin changes a system setting |
| `REFERRAL_REGENERATE` | Admin regenerates a user's referral code |

### Log Format Example
```json
{
  "id": "uuid",
  "userId": "user-uuid",
  "action": "REFERRAL_APPROVAL",
  "ipAddress": "203.0.113.10",
  "userAgent": "Flutter/3.44 Dart/3.x",
  "details": "{\"referralId\":\"ref-uuid\",\"adminId\":\"admin-uuid\"}",
  "createdAt": "2026-07-02T18:00:00Z"
}
```

### Failure Isolation
The `auditLog.service.js` wraps all DB writes in a `try/catch`. Audit log failures are logged as warnings — they **never interrupt or fail the parent request**.

---

## Schema Diagram

```
┌─────────────────┐         ┌──────────────────┐
│      User       │ 1───────│     Profile      │
│─────────────────│         │──────────────────│
│ id (PK)         │         │ id (PK)          │
│ email (unique)  │         │ userId (FK, uniq) │
│ password        │         │ firstName         │
│ role            │         │ lastName          │
│ referralCode    │         │ phoneNumber       │
│ referralUrl     │         │ avatarUrl         │
│ qrCode          │         │ bio               │
│ referrerId (FK) │─┐       └──────────────────┘
│ points          │ │
│ isApproved      │ │       ┌──────────────────┐
│ isActive        │ │       │    Referral      │
│ isDeleted       │ │       │──────────────────│
│ deletedAt       │ └──────→│ referrerId (FK)  │
│ createdAt       │         │ refereeId (FK,uniq│
│ updatedAt       │         │ status            │
└────────┬────────┘         │ points            │
         │                  └──────────────────┘
         │1                 
         │                  ┌──────────────────┐
         └─────────────────→│  HierarchyNode   │
                            │──────────────────│
                            │ userId (FK, uniq) │
                            │ parentId          │
                            │ path (indexed)    │
                            │ level             │
                            └──────────────────┘
         │
         │1..* ┌──────────────────┐
         └────→│   Notification   │
               │──────────────────│
               │ userId (FK)      │
               │ title            │
               │ message          │
               │ isRead           │
               │ type             │
               └──────────────────┘
         │
         │1..* ┌──────────────────┐
         └────→│    AuditLog      │
               │──────────────────│
               │ userId (FK,null) │
               │ action           │
               │ ipAddress        │
               │ userAgent        │
               │ details          │
               └──────────────────┘

┌──────────────────────────────┐
│       SystemSettings         │
│──────────────────────────────│
│ key (unique)                 │
│ value                        │
│ description                  │
└──────────────────────────────┘
```
