# VRIDHI — Admin Video Assignment & Unassignment Architecture

This document provides a comprehensive technical overview of the **Admin Video Assignment & Unassignment System**, detailing schema models, historical snapshot immutability safeguards, future video locking rules, and API specifications.

---

## 1. Overview & Core Philosophy

The system strictly separates **three distinct concepts**:

1. **Video Existence (`Video` model)**: Physical/meta record of a video bound to a Language and Product.
2. **Snapshot Membership (`SnapshotVideo` model)**: Historical, immutable snapshot created when a user first accesses the Video Hub. Calculates `snapshotTotalDurationSeconds` (refund denominator).
3. **Current User Video Access (`VideoAssignment` model)**: Current permissions managed by Admin for single or bulk video assignments.

---

## 2. Database Schema (`VideoAssignment`)

```prisma
model VideoAssignment {
  id           String    @id @default(uuid())
  userId       String
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  videoId      String
  video        Video     @relation(fields: [videoId], references: [id], onDelete: Cascade)
  productId    String?
  languageId   String?
  status       String    @default("ACTIVE") // ACTIVE, SUSPENDED, REVOKED, EXPIRED
  assignedAt   DateTime  @default(now())
  assignedBy   String?
  unassignedAt DateTime?
  unassignedBy String?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  @@unique([userId, videoId])
  @@index([userId])
  @@index([videoId])
  @@index([status])
}
```

---

## 3. Historical Snapshot Protection & Refund Safeguards

> [!IMPORTANT]
> **Immutability Directive**: Unassigning a video revokes the active `VideoAssignment` record but **NEVER modifies or deletes** historical `SnapshotVideo` records. This ensures that refund calculation denominators ($A + B$) remain intact and legally auditable.

- **Status Badges**:
  - `Used in User Snapshots — Deletion Protected`: Displayed when a video exists in `SnapshotVideo`. Admin deletion is blocked to prevent snapshot corruption.
  - `Active User Assignment`: Displayed when a video is assigned via `VideoAssignment`.
  - `Available for Assignment`: Displayed when a video is unassigned and not in any active user snapshot.

---

## 4. Future Video Locking Rules

Videos created after a user's snapshot date are classified as **Future Videos**.
- **Lock Conditions**: Locked until user reaches **>= 25% snapshot watch progress** OR **30 days have elapsed** since account registration.
- **User App View**:
  - `COURSE VIDEOS`: Displays unlocked videos ready for playback.
  - `LOCKED VIDEOS`: Displays blurred cards with lock icons (🔒), upload dates, and unlock progress requirements (`"Unlocks after 25% snapshot learning progress or 30 days"`).
- **Backend Playback Enforcement**: `playbackSession.service.js` rejects playback session creation with HTTP 403 if a user attempts direct playback of a locked video.

---

## 5. API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/admin/video-assignments/stats` | Dashboard metrics (Total videos, assigned, unassigned, active access, snapshot protected) |
| `GET` | `/api/v1/admin/video-assignments` | Video assignment listing with search, language filters, and status badges |
| `GET` | `/api/v1/admin/video-assignments/:id` | Video assignment detail with user list & snapshot status |
| `POST` | `/api/v1/admin/video-assignments/assign` | Single user video assignment (with full validation) |
| `POST` | `/api/v1/admin/video-assignments/bulk-assign` | Bulk video assignment to multiple users |
| `POST` | `/api/v1/admin/video-assignments/:id/unassign` | Unassign video (with snapshot protection safeguard) |
| `POST` | `/api/v1/admin/video-assignments/bulk-unassign` | Bulk video unassignment operation |
| `GET` | `/api/v1/admin/video-assignments/user/:id` | User directory Video Access breakdown |

---

## 6. Audit Logging Actions

- `VIDEO_ASSIGNED`: Single video assignment
- `VIDEO_UNASSIGNED`: Single video unassignment
- `VIDEO_BULK_ASSIGNED`: Bulk video assignment
- `VIDEO_BULK_UNASSIGNED`: Bulk video unassignment
- `VIDEO_UNASSIGN_BLOCKED`: Unassignment attempted on snapshot-protected record (historical snapshot preserved)
