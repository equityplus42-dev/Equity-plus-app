# Business Logic

> This document describes the core business workflows of the Loop Referral Network system. It is intended for developers writing new features or debugging existing behavior.

---

## Table of Contents

1. [System Configuration](#system-configuration)
2. [Registration Flow](#registration-flow)
3. [Approval Flow](#approval-flow)
4. [Referral Flow](#referral-flow)
5. [Point Distribution](#point-distribution)
6. [Hierarchy Flow](#hierarchy-flow)
7. [Visibility Rules](#visibility-rules)
8. [Notification Flow](#notification-flow)

---

## System Configuration

All system behavior parameters are stored in the `SystemSettings` table and are admin-configurable at runtime through the `PUT /api/v1/admin/settings` endpoint.

| Key | Default | Effect |
|-----|---------|--------|
| `points_level_1` | `100` | Points awarded to direct referrer (L1) when a referral is approved |
| `points_level_2` | `50` | Points awarded to the referrer's referrer (L2) |
| `points_level_3` | `25` | Points awarded three levels up (L3) |
| `max_hierarchy_depth` | `3` | Maximum depth for point distribution. Setting this to `2` stops rewards at L2. |
| `require_admin_approval` | `false` | When `false`, referrals are auto-approved on signup. When `true`, they remain `PENDING` until an admin acts. |

**No code change is required** to adjust these values. The `referral.service.js` reads fresh settings from the database on every referral event.

---

## Registration Flow

A new user registers via `POST /api/v1/auth/register`.

### Sequence

```
1. Email uniqueness check
   └─ If email already exists → Error: "Email is already registered"

2. Referral code validation (if provided)
   └─ If referralCode present → Look up user by code
   └─ If code not found → Error: "Invalid referral code"
   └─ If code valid → referrerId = referrer.id

3. Generate unique referral code for new user
   └─ Loop: generate random 8-character alphanumeric code
   └─ Check database for collision
   └─ Repeat until unique

4. Generate referral artifacts
   └─ referralUrl = "https://{APP_DOMAIN}/ref/{code}"
   └─ qrCode = base64-encoded QR image of the referralUrl

5. Hash password
   └─ bcrypt with cost factor 10

6. Create User record
   └─ { email, hashedPassword, role: "USER", referralCode, referralUrl, qrCode, referrerId }

7. Create Profile record (linked to User)
   └─ { firstName, lastName, phoneNumber }

8. Create HierarchyNode
   └─ path = parent.path + "/" + user.id (or "/" + user.id if root)
   └─ level = parent.level + 1 (or 0 if root)

9. Create Referral record (if referrerId present)
   └─ status = "PENDING" or "APPROVED" (per require_admin_approval setting)
   └─ points = points_level_1 value

10. If status === "APPROVED" → Distribute points immediately

11. Send notification to referrer (if referrerId present)
    └─ "Alice has signed up using your referral code."

12. Sign JWT
    └─ payload: { id, email, role }

13. Return { user (no password), token }
```

### Decision: Auto-Approve vs Manual Approval

```
require_admin_approval = false  →  status = "APPROVED"  →  Points distributed immediately
require_admin_approval = true   →  status = "PENDING"   →  Points distributed when admin approves
```

---

## Approval Flow

When `require_admin_approval = true`, referrals start as `PENDING` and must be reviewed by an admin.

### Admin Approve — `PATCH /api/v1/admin/referrals/:id/approve`

```
1. Look up Referral by ID
   └─ If not found → Error: "Referral record not found"
   └─ If already APPROVED → Error: "Referral is already approved"

2. Update status → "APPROVED"

3. Load system settings

4. Distribute points up the hierarchy
   └─ See Point Distribution below

5. Write audit log: REFERRAL_APPROVAL

6. Return updated Referral
```

### Admin Reject — `PATCH /api/v1/admin/referrals/:id/reject`

```
1. Look up Referral by ID
   └─ If not found → Error: "Referral record not found"
   └─ If status !== "PENDING" → Error: "Can only reject pending referrals"

2. Update status → "REJECTED"

3. Notify referrer: "Your referral of {name} was not approved."

4. Write audit log: REFERRAL_REJECTION

5. Return updated Referral
```

> **Note**: Rejection does **not** distribute any points. The referrer only receives a notification.

### Admin User Approval — `PATCH /api/v1/admin/users/:id/approval`

This is a separate concept from referral approval. It controls whether the user account itself is active (`isApproved` flag). An admin can suspend or reinstate any user account.

```
{ "isApproved": false }  →  User is suspended
{ "isApproved": true }   →  User is reinstated
```

Suspended users (`isApproved: false`) are handled at the application layer — the backend does not currently block login for `isApproved: false` users (only `isDeleted: true` blocks login). **Future feature**: Add a check in `auth.service.js` for `isApproved`.

---

## Referral Flow

The referral relationship connects a **referrer** (existing user) to a **referee** (new user who joined via the referral link).

### Core Rules

1. **Each user can only be referred once.** `Referral.refereeId` has a `@unique` constraint.
2. **A user cannot refer themselves.** (Enforced at the application layer — a valid referral code can only belong to a different user.)
3. **The referral code is permanent** but can be regenerated by an admin (`PATCH /api/v1/admin/users/:id/regenerate-referral`). Regenerating invalidates the old code and URL.

### Referral States

```
         Signup
           │
           ▼
       ┌─────────┐
       │ PENDING │
       └────┬────┘
            │
     Admin reviews
            │
     ┌──────┴──────┐
     ▼             ▼
┌──────────┐  ┌──────────┐
│ APPROVED │  │ REJECTED │
└──────────┘  └──────────┘
     │
Points distributed
```

### Referral Code Generation

```js
// services/referral/generateCode.js
generateCode(8)  // Random 8-character alphanumeric string
```

The code is checked for uniqueness in a `while` loop — collision probability is negligible for a small user base but the loop ensures correctness at any scale.

---

## Point Distribution

Point distribution is the core reward mechanism. It is triggered when a referral transitions to `APPROVED` status (either automatically on signup or when an admin approves).

### Algorithm

```
Input: refereeId, refereeName, settings

1. Find referee's HierarchyNode
   └─ If no node → return (no distribution)

2. Extract ancestors from path
   └─ path = "/A/B/C"  → ancestors = ["A", "B"]
   └─ Reversed = ["B", "A"]  (B = Level 1, A = Level 2)

3. Determine max levels
   └─ limit = min(ancestors.length, max_hierarchy_depth)

4. For each ancestor (level 1 to limit):
   a. Get points for this level:
      └─ Level 1 → points_level_1
      └─ Level 2 → points_level_2
      └─ Level 3 → points_level_3
   b. If points > 0:
      └─ prisma.user.update: points += levelPoints
   c. Send notification:
      └─ Level 1: "Referral Reward Approved! +100 points"
      └─ Level 2+: "Indirect Reward! Level 2. +50 points"
```

### Example

**Setup**: A referred B, B referred C. C's referral gets approved.

```
C's path: /A/B/C
Ancestors (excl. C): [A, B]
Reversed: [B, A]

Level 1 (B, direct referrer):  +100 points  →  REFERRAL_APPROVED notification
Level 2 (A, indirect):         +50 points   →  SYSTEM notification
```

**If `max_hierarchy_depth = 1`**: Only B receives points. A receives nothing.

### Points Immutability

Once distributed, points are **never deducted** if a referral is later rejected. The rejection flow only applies to `PENDING` referrals — an `APPROVED` referral cannot be un-approved through the current API.

---

## Hierarchy Flow

The hierarchy represents the entire downline tree of all users.

### Node Creation

A `HierarchyNode` is created for **every** registered user, even those who join without a referral code (they become root nodes at `level = 0`).

```
User A (no referrer):
  path = "/A"
  level = 0
  parentId = null

User B (referred by A):
  path = "/A/B"
  level = 1
  parentId = A

User C (referred by B):
  path = "/A/B/C"
  level = 2
  parentId = B

User D (referred by A directly):
  path = "/A/D"
  level = 1
  parentId = A
```

### Tree View (Visual)

```
A (level 0)
├── B (level 1)
│   └── C (level 2)
└── D (level 1)
```

### Descendant Query

When a user views their hierarchy, the query is:
```
HierarchyNode WHERE path STARTS WITH "/A/"
```
This returns B, C, and D in a single indexed query — no recursion.

### Tree Building

After querying flat nodes, `hierarchyHelper.buildTree()` assembles the nested structure:
```json
[
  {
    "id": "B",
    "name": "Bob",
    "level": 1,
    "children": [
      { "id": "C", "name": "Carol", "level": 2, "children": [] }
    ]
  },
  {
    "id": "D",
    "name": "Dave",
    "level": 1,
    "children": []
  }
]
```

### Admin vs User View

- **User view** (`GET /hierarchy/my`): Shows only the requesting user's downline subtree.
- **Admin view** (`GET /hierarchy/global`): Shows all nodes in the system, starting from all root nodes (`level = 0`).

---

## Visibility Rules

These rules govern what data each role can see and modify.

### Regular User (`role = "USER"`)

| Resource | Read | Write |
|----------|------|-------|
| Own profile | ✅ | ✅ |
| Other profiles | ❌ | ❌ |
| Own referral list | ✅ | ❌ |
| Own hierarchy subtree | ✅ | ❌ |
| Global hierarchy | ❌ | ❌ |
| Own notifications | ✅ | ✅ (mark read) |
| System settings | ✅ (read only) | ❌ |
| Admin stats | ❌ | ❌ |
| Other users' referrals | ❌ | ❌ |

### Administrator (`role = "ADMIN"`)

| Resource | Read | Write |
|----------|------|-------|
| All users | ✅ | ✅ (approve/suspend/delete) |
| All referrals | ✅ | ✅ (approve/reject) |
| Global hierarchy | ✅ | ❌ (read only) |
| System settings | ✅ | ✅ |
| Dashboard stats | ✅ | ❌ |
| User referral codes | ✅ | ✅ (regenerate) |

### Enforcement

Visibility rules are enforced by the middleware stack:
- **User routes**: `authMiddleware` only → any authenticated user.
- **Admin routes**: `authMiddleware` + `adminMiddleware` → ADMIN role only.
- **Own data**: Enforced in the service layer using `req.user.id` to scope queries.

There is no role hierarchy beyond USER and ADMIN. An admin can do everything a user can plus admin actions.

---

## Notification Flow

Every significant event triggers an in-app notification and a concurrent Firebase push notification.

### Notification Creation Sequence

```
Business event occurs (e.g., referral approved)
    │
    ▼
notificationService.notifyXxx(userId, ...)
    │
    ├─── 1. notificationRepository.createNotification({ userId, title, message, type })
    │         └─ Writes to Notification table (always)
    │
    └─── 2. firebaseService.sendPushNotification(userId, { title, body, data })
              └─ Sends FCM push notification
              └─ If FCM fails → logger.error() — does NOT throw
```

### Notification Types and Their Triggers

| Type | Trigger | Recipient |
|------|---------|-----------|
| `REFERRAL_SIGNUP` | New user registers with the referrer's code | Referrer |
| `REFERRAL_APPROVED` | Admin approves referral | Direct referrer (L1) |
| `REFERRAL_REJECTED` | Admin rejects referral | Direct referrer |
| `SYSTEM` | Indirect reward (L2, L3 in hierarchy) | Ancestor at that level |

### FCM Push Notification Data Payload

```json
{
  "title": "Referral Reward Approved! 💰",
  "body": "Your referral of Alice was approved. You received +100 points!",
  "data": {
    "type": "REFERRAL_APPROVED",
    "notificationId": "notif-uuid"
  }
}
```

The `notificationId` in the `data` payload allows the Flutter app to navigate directly to the relevant notification in the app when the push is tapped.

### Notification Lifecycle

```
Created (isRead: false)
    │
    │ User opens notifications list
    ▼
Displayed in NotificationsScreen
    │
    │ User taps "Mark as read" or "Mark all read"
    ▼
isRead: true → disappears from unread badge count
```

Notifications are **never deleted** — they are only marked as read. This provides a complete notification history.
