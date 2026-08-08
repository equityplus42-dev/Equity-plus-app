# Vridhi Refund Subsystem Architecture

## 1. Snapshot Integration
Refund requests consume the **authoritative `UserVideoSnapshot.refundEligible`** status and live watch progress percentage.

```text
Snapshot Progress < 25% AND Joined Days < 30
                   │
                   ▼
       Refund Request Eligible
                   │
                   ▼
POST /api/v1/refunds/request (Status: PENDING)
                   │
                   ▼
Admin Review (PATCH /api/v1/refunds/admin/:id/review)
        /                     \
       /                       \
  APPROVED                  REJECTED
     │
     ▼
 PROCESSED (Payment status: REFUNDED)
```

## 2. State Machine Transitions
- `PENDING` $\rightarrow$ `UNDER_REVIEW`, `APPROVED`, `REJECTED`
- `UNDER_REVIEW` $\rightarrow$ `APPROVED`, `REJECTED`
- `APPROVED` $\rightarrow$ `PROCESSED` (Sets Payment `status = REFUNDED`)
- `PROCESSED` / `REJECTED`: **Terminal States** (No further transitions allowed).

## 3. Disambiguation: APPROVED vs PROCESSED
- **`APPROVED`**: Represents the administrative business decision to approve a user's refund application.
- **`PROCESSED`**: Represents the actual financial payout completion (manually or via gateway payout reference).
