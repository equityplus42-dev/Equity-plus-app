# Software Requirements Specification (SRS)

## 1. Introduction
This system is a **Hierarchical Referral System** designed to track user registrations via referral codes and distribute reward points across a multi-level tree hierarchy.

## 2. Functional Requirements
- **Authentication**: Users and Admins can register and log in. Admins must have the `ADMIN` role.
- **Referral Code**: Upon registration, each user is automatically assigned a unique 8-character uppercase alphanumeric referral code.
- **Referral Tree**: When a user registers using another user's referral code, they are linked in a self-referencing relationship.
- **Multi-Level Rewards**: Points are distributed up the network tree up to a configurable max depth (default: 3 levels).
- **Admin Approval**: If manual approvals are enabled, rewards points are pending until the admin approves. If disabled, points are distributed automatically upon referee sign up.
- **User Dashboard**: Displays point balances, referral counts, and invitation links/QR codes.
- **Admin Dashboard**: Displays aggregate stats (total users, points, pending counts) and admin actions (directory, approvals lists, settings, tree map).

## 3. Non-Functional Requirements
- **Performance**: Materialized paths are utilized in SQL database queries for rapid O(1) downline subtree rendering.
- **Security**: Passwords are encrypted using bcrypt hashing. Tokens are signed via HS256 JWTs.
- **Resiliency**: Upload flows fall back gracefully to premium mock avatars if Cloudinary API parameters are omitted from env files.
