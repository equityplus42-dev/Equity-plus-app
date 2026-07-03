# REST API Reference (API Version: v1)

All requests must be sent with headers:
```http
Content-Type: application/json
Accept: application/json
```
For protected endpoints, include:
```http
Authorization: Bearer <JWT_Token>
```

---

## 1. Authentication Routes

### Register
`POST /api/v1/auth/register`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890",
    "referralCode": "ADMINREF"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "Registration successful",
    "data": {
      "user": {
        "id": "user-uuid",
        "email": "user@example.com",
        "role": "USER",
        "referralCode": "USERREF8",
        "referralUrl": "https://referral-system.com/r/USERREF8",
        "points": 0,
        "isApproved": true
      },
      "token": "jwt-token-string"
    }
  }
  ```

### Login
`POST /api/v1/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "user": { ... },
      "token": "jwt-token-string"
    }
  }
  ```

---

## 2. Personal Referral & Profile Routes

### Get Personal Profile
`GET /api/v1/users/profile`

### Update Profile Details
`PUT /api/v1/profile`
- **Request Body**:
  ```json
  {
    "firstName": "NewFirst",
    "lastName": "NewLast",
    "phoneNumber": "+987654321",
    "bio": "Biography text..."
  }
  ```

### Upload Profile Picture (Memory Storage Buffer)
`POST /api/v1/profile/avatar`
- **Request Type**: `multipart/form-data`
- **Fields**: `avatar` (file buffer)

### Get Referral Logs
`GET /api/v1/referrals`

### Get Referral Stats
`GET /api/v1/referrals/stats`

### Get Referral QR Code & URL
`GET /api/v1/referrals/qr`
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "referralCode": "USERREF8",
      "referralUrl": "https://referral-system.com/r/USERREF8",
      "qrCode": "data:image/png;base64,iVBORw0KG..."
    }
  }
  ```

### Get Downline Hierarchy Tree
`GET /api/v1/hierarchy?depth=3`

### Search Visible Hierarchy Downlines
`GET /api/v1/search?query=John`

---

## 3. Admin Control Routes

### Get Admin Stats
`GET /api/v1/admin/stats`

### Get Pending Referral Approvals
`GET /api/v1/admin/referrals/pending`

### Approve Referral Reward
`PATCH /api/v1/admin/referrals/:referralId/approve`

### Reject Referral Reward
`PATCH /api/v1/admin/referrals/:referralId/reject`

### Toggle User Account Suspension
`PATCH /api/v1/admin/users/:userId/approval`
- **Request Body**:
  ```json
  {
    "isApproved": false
  }
  ```

### Regenerate User Referral Code, Link, and QR Code
`PATCH /api/v1/admin/users/:userId/regenerate-referral`

### Update Campaign Configurations
`PUT /api/v1/admin/settings`
- **Request Body**:
  ```json
  {
    "key": "points_level_1",
    "value": "150",
    "description": "Updated direct reward points"
  }
  ```
