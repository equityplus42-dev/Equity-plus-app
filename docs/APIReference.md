# API Reference

> **Base URL**: `https://your-domain.com/api/v1`
> **Content-Type**: `application/json`
> **Authentication**: `Authorization: Bearer <JWT Token>`
> **Interactive Docs**: Available at `/api/docs` (Swagger UI)

---

## Table of Contents

1. [Standard Response Format](#standard-response-format)
2. [Error Codes](#error-codes)
3. [Rate Limits](#rate-limits)
4. [Authentication Endpoints](#authentication-endpoints)
5. [User Endpoints](#user-endpoints)
6. [Profile Endpoints](#profile-endpoints)
7. [Referral Endpoints](#referral-endpoints)
8. [Hierarchy Endpoints](#hierarchy-endpoints)
9. [Notification Endpoints](#notification-endpoints)
10. [Admin Endpoints](#admin-endpoints)
11. [Settings Endpoints](#settings-endpoints)
12. [Search Endpoints](#search-endpoints)
13. [Health Endpoint](#health-endpoint)

---

## Standard Response Format

### Success Response
```json
{
  "success": true,
  "message": "Human-readable description",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Human-readable description",
  "errorCode": "AUTH_001"
}
```

### Paginated Response
```json
{
  "success": true,
  "message": "...",
  "data": {
    "items": [ ... ],
    "total": 150,
    "page": 1,
    "limit": 10,
    "totalPages": 15
  }
}
```

---

## Error Codes

| Code | Category | Meaning |
|------|----------|---------|
| `AUTH_001` | Authentication | Invalid email or password |
| `AUTH_002` | Authentication | Unauthorized — no valid token |
| `AUTH_003` | Authentication | JWT token has expired |
| `AUTH_004` | Authentication | Rate limit exceeded for auth endpoint |
| `AUTH_RATE_LIMIT_LOGIN` | Rate Limit | Too many login attempts |
| `AUTH_RATE_LIMIT_REGISTER` | Rate Limit | Too many registration attempts |
| `AUTH_RATE_LIMIT_FORGOT` | Rate Limit | Too many forgot-password requests |
| `USER_001` | User | User not found |
| `USER_002` | User | Email already registered |
| `USER_003` | User | Account is suspended or deleted |
| `REFERRAL_001` | Referral | Invalid referral code |
| `REFERRAL_002` | Referral | Referral relationship already exists |
| `HIERARCHY_001` | Hierarchy | Circular reference detected |
| `HIERARCHY_002` | Hierarchy | Hierarchy node not found |
| `VALIDATION_001` | Validation | Request body failed validation |
| `SYS_001` | System | Database or internal server error |
| `SYS_002` | System | Requested resource not found |

---

## Rate Limits

| Endpoint | Window | Max Requests |
|----------|--------|-------------|
| `POST /auth/login` | 60 seconds | 5 |
| `POST /auth/register` | 60 seconds | 3 |
| `POST /auth/forgot-password` | 60 seconds | 3 |
| All other `/api/*` endpoints | 15 minutes | 100 (per IP) |

When a limit is exceeded, the response is HTTP `429` with the appropriate `AUTH_RATE_LIMIT_*` error code.

---

## Authentication Endpoints

### `POST /api/v1/auth/register`

Register a new user. Optionally include a referral code to link to a referrer.

**Rate limit**: 3 requests per minute.
**Authentication**: Not required.

#### Request Body

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "referralCode": "ABCD1234",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `email` | string | ✅ | Must be a valid email |
| `password` | string | ✅ | Minimum 6 characters |
| `referralCode` | string | ❌ | 8-char code from another user |
| `firstName` | string | ❌ | |
| `lastName` | string | ❌ | |
| `phoneNumber` | string | ❌ | |

#### Success Response — HTTP 201

```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "role": "USER",
      "referralCode": "XZ9P3K2M",
      "referralUrl": "https://referral-system.com/ref/XZ9P3K2M",
      "qrCode": "data:image/png;base64,...",
      "points": 0,
      "profile": {
        "firstName": "John",
        "lastName": "Doe",
        "phoneNumber": "+1234567890",
        "avatarUrl": null
      }
    },
    "token": "eyJhbGci..."
  }
}
```

#### Error Responses

| HTTP | Error Code | Cause |
|------|-----------|-------|
| 400 | `VALIDATION_001` | Invalid email or missing password |
| 400 | — | Email already registered |
| 400 | — | Invalid referral code |
| 429 | `AUTH_RATE_LIMIT_REGISTER` | Rate limit exceeded |

---

### `POST /api/v1/auth/login`

Authenticate an existing user and receive a JWT.

**Rate limit**: 5 requests per minute.
**Authentication**: Not required.

#### Request Body

```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "role": "USER",
      "referralCode": "XZ9P3K2M",
      "referralUrl": "https://referral-system.com/ref/XZ9P3K2M",
      "qrCode": "data:image/png;base64,...",
      "points": 150,
      "profile": { ... }
    },
    "token": "eyJhbGci..."
  }
}
```

#### Error Responses

| HTTP | Error Code | Cause |
|------|-----------|-------|
| 401 | `AUTH_001` | Wrong email or password |
| 429 | `AUTH_RATE_LIMIT_LOGIN` | Rate limit exceeded |

---

### `POST /api/v1/auth/logout`

Signals a logout. The client must discard the token locally.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

### `POST /api/v1/auth/forgot-password`

Placeholder endpoint; returns a success acknowledgement.

**Rate limit**: 3 requests per minute.
**Authentication**: Not required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Password reset link dispatched."
}
```

---

## User Endpoints

### `GET /api/v1/users/profile`

Get the currently authenticated user's profile.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "USER",
    "points": 250,
    "referralCode": "XZ9P3K2M",
    "referralUrl": "https://referral-system.com/ref/XZ9P3K2M",
    "profile": {
      "firstName": "John",
      "lastName": "Doe",
      "avatarUrl": "https://res.cloudinary.com/..."
    }
  }
}
```

---

### `GET /api/v1/users`

List all users (paginated). **Admin only**.

**Authentication**: Required (Admin role).

#### Query Parameters

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | number | 1 | Page number |
| `limit` | number | 10 | Items per page (max 100) |
| `search` | string | — | Search by email, first name, or last name |

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": {
    "items": [ { "id": "...", "email": "...", "profile": {...} } ],
    "total": 500,
    "page": 1,
    "limit": 10,
    "totalPages": 50
  }
}
```

---

### `GET /api/v1/users/:id`

Get a specific user by ID. **Admin only**.

**Authentication**: Required (Admin role).

---

### `DELETE /api/v1/users/:id`

Soft-delete a user. The user record is retained with `isDeleted: true`. **Admin only**.

**Authentication**: Required (Admin role).

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

---

## Profile Endpoints

### `PUT /api/v1/profile`

Update the authenticated user's profile fields.

**Authentication**: Required.

#### Request Body

```json
{
  "firstName": "Jane",
  "lastName": "Doe",
  "phoneNumber": "+9876543210",
  "bio": "Referral enthusiast!"
}
```

All fields are optional. Only provided fields are updated.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": { "id": "...", "firstName": "Jane", ... }
}
```

---

### `POST /api/v1/profile/avatar`

Upload a new profile avatar image.

**Authentication**: Required.
**Content-Type**: `multipart/form-data`

#### Request

Form-data field: `avatar` — image file (max 5 MB, image/* MIME types only).

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Avatar uploaded successfully",
  "data": {
    "avatarUrl": "https://res.cloudinary.com/your-cloud/image/upload/avatars/abc123.jpg"
  }
}
```

#### Error Responses

| HTTP | Cause |
|------|-------|
| 400 | No file attached |
| 400 | File type not image |
| 413 | File exceeds 5 MB |

---

## Referral Endpoints

### `GET /api/v1/referrals/my`

Get the authenticated user's referrals (people they referred).

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": [
    {
      "id": "ref-uuid",
      "refereeId": "user-uuid",
      "status": "APPROVED",
      "points": 100,
      "createdAt": "2026-01-15T10:00:00Z",
      "referee": {
        "email": "referee@example.com",
        "profile": { "firstName": "Alice", "avatarUrl": null }
      }
    }
  ]
}
```

---

### `GET /api/v1/referrals/stats`

Get aggregated referral statistics for the current user.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": {
    "total": 15,
    "approved": 12,
    "pending": 2,
    "rejected": 1,
    "totalPointsEarned": 1500
  }
}
```

---

### `GET /api/v1/referrals/validate/:code`

Validate whether a referral code exists before the user registers.

**Authentication**: Not required (public).

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": { "valid": true, "referrerName": "John Doe" }
}
```

---

## Hierarchy Endpoints

### `GET /api/v1/hierarchy/my`

Get the authenticated user's downline hierarchy tree.

**Authentication**: Required.

#### Query Parameters

| Param | Default | Description |
|-------|---------|-------------|
| `depth` | `max_hierarchy_depth` | Limit tree depth |

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": [
    {
      "id": "user-A",
      "name": "Alice",
      "level": 1,
      "avatarUrl": null,
      "children": [
        {
          "id": "user-B",
          "name": "Bob",
          "level": 2,
          "children": []
        }
      ]
    }
  ]
}
```

---

### `GET /api/v1/hierarchy/global`

Get the full system-wide hierarchy. **Admin only**.

**Authentication**: Required (Admin role).

Returns the same nested tree structure but starting from all root nodes.

---

## Notification Endpoints

### `GET /api/v1/notifications`

Fetch all notifications for the current user, sorted by most recent.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": [
    {
      "id": "notif-uuid",
      "title": "New Referral Signup! 🎉",
      "message": "Alice has signed up using your referral code.",
      "type": "REFERRAL_SIGNUP",
      "isRead": false,
      "createdAt": "2026-07-01T12:00:00Z"
    }
  ]
}
```

---

### `PATCH /api/v1/notifications/:id/read`

Mark a single notification as read.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{ "success": true, "message": "Notification marked as read" }
```

---

### `PATCH /api/v1/notifications/read-all`

Mark all of the current user's notifications as read.

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{ "success": true, "message": "All notifications marked as read" }
```

---

## Admin Endpoints

All admin endpoints require the `Authorization: Bearer <token>` header with an **ADMIN role** token.

### `GET /api/v1/admin/stats`

Get dashboard statistics.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": {
    "totalUsers": 500,
    "pendingApprovals": 12,
    "approvedReferrals": 430,
    "totalReferrals": 450,
    "totalPointsDistributed": 65000,
    "recentSignups": [ { ... } ]
  }
}
```

---

### `PATCH /api/v1/admin/users/:userId/approval`

Approve or suspend a user account.

#### Request Body

```json
{ "isApproved": true }
```

---

### `GET /api/v1/admin/referrals/pending`

Get all referrals with `PENDING` status.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": [
    {
      "id": "ref-uuid",
      "referrerId": "...",
      "refereeId": "...",
      "status": "PENDING",
      "createdAt": "...",
      "referrer": { "email": "...", "profile": { ... } },
      "referee": { "email": "...", "profile": { ... } }
    }
  ]
}
```

---

### `PATCH /api/v1/admin/referrals/:referralId/approve`

Approve a pending referral. Triggers point distribution and notifications.

#### Success Response — HTTP 200

```json
{ "success": true, "message": "Referral reward approved successfully" }
```

---

### `PATCH /api/v1/admin/referrals/:referralId/reject`

Reject a pending referral. Notifies the referrer.

#### Success Response — HTTP 200

```json
{ "success": true, "message": "Referral reward rejected successfully" }
```

---

### `PUT /api/v1/admin/settings`

Create or update a system setting.

#### Request Body

```json
{
  "key": "points_level_1",
  "value": "150",
  "description": "Points awarded for direct referrals"
}
```

| Field | Required |
|-------|----------|
| `key` | ✅ |
| `value` | ✅ |
| `description` | ❌ |

---

### `PATCH /api/v1/admin/users/:userId/regenerate-referral`

Regenerate a user's referral code, URL, and QR code.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "User referral details regenerated",
  "data": {
    "referralCode": "NEW8CODE",
    "referralUrl": "https://referral-system.com/ref/NEW8CODE",
    "qrCode": "data:image/png;base64,..."
  }
}
```

---

## Settings Endpoints

### `GET /api/v1/settings`

Get current public system settings (available to authenticated users).

**Authentication**: Required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": [
    { "key": "points_level_1", "value": "100" },
    { "key": "points_level_2", "value": "50" },
    { "key": "max_hierarchy_depth", "value": "3" },
    { "key": "require_admin_approval", "value": "false" }
  ]
}
```

---

## Search Endpoints

### `GET /api/v1/search`

Search users by name or email.

**Authentication**: Required.

#### Query Parameters

| Param | Required | Description |
|-------|----------|-------------|
| `q` | ✅ | Search query string |
| `page` | ❌ | Page number (default 1) |
| `limit` | ❌ | Results per page (default 10) |

#### Success Response — HTTP 200

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "email": "alice@example.com",
        "profile": { "firstName": "Alice", "lastName": "Smith", "avatarUrl": null }
      }
    ],
    "total": 3,
    "page": 1,
    "limit": 10
  }
}
```

---

## Health Endpoint

### `GET /api/v1/health`

Server and database health check. Used by monitoring services and deployment pipelines.

**Authentication**: Not required.

#### Success Response — HTTP 200

```json
{
  "success": true,
  "message": "Server running",
  "version": "1.0.0",
  "database": "Connected"
}
```

#### Failure Response — HTTP 500

```json
{
  "success": false,
  "message": "Server running with database issues",
  "version": "1.0.0",
  "database": "Disconnected"
}
```
