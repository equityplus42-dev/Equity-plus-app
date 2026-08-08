# Vridhi Product Access & Authorization Architecture

## 1. Overview
Product Access follows a strict **Payment $\rightarrow$ Admin Approval $\rightarrow$ Active Access** workflow to separate financial transaction success from administrative authorization.

## 2. State Machine
```text
Payment SUCCESS
      │
      ▼
UserProductAccess: PENDING_APPROVAL
      │
      ▼
Admin Review (PATCH /api/v1/products/admin/access/:id/approve)
      │
      ▼
UserProductAccess: ACTIVE
      │
      ▼
Video Streaming Access Granted (GET /api/v1/videos/:id/access)
```

## 3. Server-Side Security
Video access endpoints (`GET /api/v1/videos/:id/access`) enforce product authorization server-side:
```javascript
if (video.productId) {
  const hasAccess = await productAccessService.hasActiveAccess(userId, video.productId);
  if (!hasAccess) {
    throw new Error('Active product access required to stream this video');
  }
}
```
Frontend UI hiding is **never** relied upon as security.
