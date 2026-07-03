# Security Guide

---

## Table of Contents

1. [JWT Authentication Flow](#jwt-authentication-flow)
2. [Password Hashing](#password-hashing)
3. [Rate Limiting](#rate-limiting)
4. [Helmet (HTTP Security Headers)](#helmet)
5. [CORS](#cors)
6. [Soft Delete & Account Security](#soft-delete--account-security)
7. [Audit Logging](#audit-logging)
8. [Cloudinary Upload Flow](#cloudinary-upload-flow)
9. [Input Validation](#input-validation)
10. [Security Checklist](#security-checklist)

---

## JWT Authentication Flow

The system uses **JSON Web Tokens (JWT)** for stateless authentication. No sessions or cookies are required.

### Token Structure

A JWT contains three base64url-encoded parts:
```
Header.Payload.Signature
```

**Payload** (the decoded claims):
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "role": "USER",
  "iat": 1751875200,
  "exp": 1752480000
}
```

### Token Signing

Implemented in `services/jwt.service.js`:
```js
jwt.sign({ id, email, role }, jwtConfig.secret, { expiresIn: jwtConfig.expiresIn })
```

- **Algorithm**: HS256 (HMAC-SHA256)
- **Secret**: `JWT_SECRET` env var (must be a long, random string in production)
- **Default expiry**: 7 days (`JWT_EXPIRES_IN`)

### Authentication Flow

```
Client                              Server
  │                                   │
  │ POST /auth/login                  │
  │ { email, password }               │
  │──────────────────────────────────→│
  │                                   │ 1. Find user by email
  │                                   │ 2. Check isDeleted flag
  │                                   │ 3. bcrypt.compare(password, hash)
  │                                   │ 4. jwt.sign({ id, email, role })
  │                                   │
  │ { token: "eyJhbGci..." }          │
  │←──────────────────────────────────│
  │                                   │
  │ Store token in SharedPreferences  │
  │                                   │
  │ GET /api/v1/users/profile         │
  │ Authorization: Bearer eyJhbGci…  │
  │──────────────────────────────────→│
  │                                   │ 1. Extract token from header
  │                                   │ 2. jwt.verify(token, secret)
  │                                   │ 3. Decode → req.user = { id, email, role }
  │                                   │ 4. Call controller
  │                                   │
  │ { success: true, data: {...} }     │
  │←──────────────────────────────────│
```

### Token Verification (`auth.middleware.js`)

```js
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return ApiResponse.error(res, 'Access denied. No token provided.', 401);
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, jwtConfig.secret);
    req.user = decoded;  // { id, email, role }
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return ApiResponse.error(res, 'Token expired.', 401);
    }
    return ApiResponse.error(res, 'Invalid token.', 401);
  }
}
```

### Token Storage (Flutter)

Tokens are stored in `SharedPreferences` (Android: encrypted internal storage; iOS: NSUserDefaults). The `StorageService` class manages reading and writing the token.

### Security Considerations

- **The token secret** must be a long, unpredictable random string in production. Never use the fallback `'referral_system_secret_key_123'`.
- **Token expiry** is set to 7 days. Once expired, the user must log in again.
- **Stateless**: The server holds no session state — token validation is purely cryptographic.
- **No token blacklisting**: Logout is client-side only (the client discards the token). Implementing token blacklisting would require a Redis cache.

---

## Password Hashing

Implemented in `utils/encryption.js` using the `bcrypt` library.

### Hashing

```js
async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);  // Cost factor: 10
  return bcrypt.hash(password, salt);
}
```

- **Cost factor 10**: Approximately 100–200ms to hash on modern hardware. Provides strong protection against brute-force attacks.
- The salt is automatically embedded in the hash string — no separate salt storage is needed.

### Comparison

```js
async function comparePassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}
```

`bcrypt.compare` is **timing-safe** — it does not short-circuit on the first character mismatch, preventing timing attacks.

### What Is Never Done

- Passwords are never logged.
- Passwords are never stored in plaintext.
- Passwords are stripped from all API response objects before they are returned:
  ```js
  const { password: _, ...userWithoutPassword } = user;
  return { user: userWithoutPassword, token };
  ```

---

## Rate Limiting

Three layers of rate limiting protect the API.

### Layer 1: Global Limit (All `/api/*` Routes)

Configured in `app.js`:
```js
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15-minute window
  max: 100,                   // Max 100 requests per IP
});
app.use('/api', limiter);
```

This protects against general API abuse and DoS attacks.

### Layer 2: Auth Route Limits (`rateLimit.middleware.js`)

Stricter limits on sensitive authentication endpoints:

| Endpoint | Window | Max Requests |
|----------|--------|-------------|
| `POST /auth/login` | 60 s | 5 |
| `POST /auth/register` | 60 s | 3 |
| `POST /auth/forgot-password` | 60 s | 3 |

### Layer 3: Standard Headers

All rate limiters use:
```js
standardHeaders: true,   // Returns RateLimit-* headers
legacyHeaders: false,    // No X-RateLimit-* headers
```

The `RateLimit-Remaining` and `RateLimit-Reset` headers are visible to clients for implementing backoff logic.

### Rate Limit Response

When exceeded, the response is HTTP `429`:
```json
{
  "success": false,
  "message": "Too many login attempts, please try again in a minute.",
  "errorCode": "AUTH_RATE_LIMIT_LOGIN"
}
```

The Flutter apps receive this `errorCode` and display an appropriate message to the user.

---

## Helmet

`helmet()` is applied as the **first** middleware in `app.js`. It automatically sets a collection of security-relevant HTTP response headers.

### Headers Set by Helmet

| Header | Purpose |
|--------|---------|
| `Content-Security-Policy` | Prevents XSS by restricting resource origins |
| `X-Frame-Options: SAMEORIGIN` | Prevents clickjacking |
| `X-Content-Type-Options: nosniff` | Prevents MIME type sniffing |
| `Strict-Transport-Security` | Forces HTTPS (in production) |
| `X-DNS-Prefetch-Control: off` | Disables DNS prefetching |
| `Referrer-Policy: no-referrer` | Controls referrer header leakage |

These are important even for a mobile-only API backend because they protect against attacks if the API is ever accessed from a browser (e.g., via Swagger UI or Postman Web).

---

## CORS

`cors()` is applied after Helmet.

### Current Configuration

```js
app.use(cors());
```

This allows all origins — suitable for development and when the API is consumed only by mobile apps (which are not subject to same-origin policy enforcement).

### Recommended Production Configuration

For a production API with known consumers:

```js
app.use(cors({
  origin: [
    'https://your-admin-dashboard.com',
    'https://your-marketing-site.com',
  ],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
```

> **Note**: Native mobile apps (Flutter) are not subject to CORS restrictions. CORS only applies to browser-based clients.

---

## Soft Delete & Account Security

Soft deletion prevents data loss while also disabling account access.

### Security Implications

1. **Login is blocked** for soft-deleted users:
   ```js
   if (!user || user.isDeleted) {
     throw new Error('Invalid email or password');
   }
   ```
   The error message is deliberately generic to prevent **user enumeration** (an attacker cannot distinguish between "email not found" and "account deleted").

2. **Deleted accounts cannot be re-registered** with the same email. The `email @unique` constraint in the database ensures the email remains taken even after soft deletion.

3. **Account suspension** (`isApproved: false`) is a separate flag — a suspended user's record exists and their email is still linked, but they should be blocked at the application layer.

---

## Audit Logging

All security-critical actions are recorded in the `AuditLog` database table.

### What Is Logged

| Action | When |
|--------|------|
| `LOGIN` | Every successful login |
| `REGISTER` | Every new account creation |
| `PROFILE_UPDATE` | User edits their profile |
| `AVATAR_UPDATE` | User uploads a new avatar |
| `USER_DELETE` | Admin soft-deletes a user |
| `USER_APPROVE` / `USER_SUSPEND` | Admin changes approval status |
| `REFERRAL_APPROVAL` / `REFERRAL_REJECTION` | Admin acts on a referral |
| `ADMIN_SETTINGS_UPDATE` | Admin changes a system setting |
| `REFERRAL_REGENERATE` | Admin regenerates a user's referral code |

### Data Captured Per Log Entry

```json
{
  "userId": "acting-user-uuid",
  "action": "LOGIN",
  "ipAddress": "203.0.113.45",
  "userAgent": "Flutter/3.44",
  "details": "{\"email\":\"user@example.com\"}",
  "createdAt": "2026-07-02T18:00:00.000Z"
}
```

### Failure Isolation

The `auditLog.service.js` wraps all database writes in a `try/catch`. An audit log write failure is logged as a `warn` message but **never throws** and **never interrupts** the parent request. This ensures that logging infrastructure problems cannot cause user-facing errors.

---

## Cloudinary Upload Flow

All image uploads go through Cloudinary. No images are ever stored on the application server.

### Full Flow

```
Flutter App
    │
    │ POST /api/v1/profile/avatar
    │ Content-Type: multipart/form-data
    │ body: { avatar: <image bytes> }
    │
    ▼
Express + Multer (memoryStorage)
    │ file → req.file.buffer (Buffer in RAM)
    │ NO disk write occurs
    │ File filter: only image/* MIME types accepted
    │ Size limit: 5 MB
    │
    ▼
upload.middleware.js
    │ upload.single('avatar')
    │
    ▼
profileController.uploadAvatar(req, res, next)
    │ checks: if (!req.file) → 400
    │ calls: profileService.updateAvatar(userId, req.file.buffer)
    │
    ▼
cloudinaryService.uploadImage(buffer, 'avatars')
    │ Creates a Readable stream from the Buffer
    │ Pipes to cloudinary.uploader.upload_stream({ folder: 'avatars' })
    │ Cloudinary processes and CDN-distributes the image
    │ Returns result.secure_url (HTTPS URL)
    │
    ▼
profileRepository.updateAvatarUrl(userId, secureUrl)
    │ Stores the URL string in Profile.avatarUrl (TiDB)
    │
    ▼
Response to Flutter: { avatarUrl: "https://res.cloudinary.com/..." }
```

### Security Properties

- **No local storage**: The `Buffer` lives only in process memory during the request.
- **Validation before upload**: MIME type and file size are checked by Multer before Cloudinary is even contacted.
- **CDN delivery**: Cloudinary serves images via its global CDN — the backend URL is never used to serve images.
- **Secure URLs**: Cloudinary returns `https://` URLs only (`result.secure_url`).

---

## Input Validation

### Backend Validation

All request bodies that modify data pass through `validation.middleware.js` which runs a Joi schema validation before the request reaches the controller.

- Returns HTTP `400` with field-level errors if validation fails.
- Prevents SQL injection through ORM parameterization (Prisma never interpolates raw user input into SQL).
- Prevents object injection by validating types and shapes.

### Flutter Input Validation

Both Flutter apps validate user input at the UI layer (form validators) before sending network requests, reducing unnecessary API calls.

---

## Security Checklist

Use this checklist before any production deployment:

### Authentication & Authorization
- [ ] `JWT_SECRET` is at least 64 characters, randomly generated
- [ ] `JWT_EXPIRES_IN` is set to a reasonable duration (`7d` or less)
- [ ] All protected routes have `authMiddleware` applied
- [ ] All admin routes have both `authMiddleware` and `adminMiddleware` applied

### Passwords
- [ ] Passwords are hashed with bcrypt (cost factor ≥ 10)
- [ ] No password is ever returned in any API response
- [ ] No password is ever logged

### Rate Limiting
- [ ] Global rate limit is active on all `/api/*` routes
- [ ] Login, register, and forgot-password have stricter per-route limits

### Environment
- [ ] `NODE_ENV=production` is set
- [ ] `.env` file is not committed to Git
- [ ] Vercel environment variables are set in the dashboard (not in code)
- [ ] Database URL uses SSL (`sslaccept=strict`)

### Headers
- [ ] `helmet()` is the first middleware in `app.js`
- [ ] CORS is restricted to known origins in production

### Uploads
- [ ] Multer uses `memoryStorage()` — no disk writes
- [ ] File filter restricts to `image/*` only
- [ ] File size limit is enforced (5 MB)
- [ ] Cloudinary credentials are set in environment

### Logging & Monitoring
- [ ] `LOG_LEVEL=info` in production
- [ ] Audit log table is being populated
- [ ] Health check endpoint is monitored by an uptime service
