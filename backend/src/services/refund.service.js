const prisma = require('../config/database');
const videoService = require('./video.service');

class RefundService {
  /**
   * Create a Refund Request (Verifies eligibility server-side via Snapshot engine)
   */
  async createRefundRequest({ userId, paymentId, reason, bankDetails, additionalDetails }) {
    // 1. Verify Payment exists and belongs to user
    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
    });
    if (!payment) {
      throw new Error('Payment record not found');
    }
    if (payment.userId !== userId) {
      throw new Error('Unauthorized refund request for this payment');
    }
    if (payment.status !== 'SUCCESS') {
      throw new Error('Refund can only be requested for successful payments');
    }

    // 2. Check snapshot eligibility server-side (NEVER trust frontend)
    const snapshot = await prisma.userVideoSnapshot.findUnique({
      where: { userId },
    });

    if (!snapshot) {
      throw new Error('No learning snapshot found for this account');
    }

    if (!snapshot.refundEligible) {
      throw new Error('Refund eligibility has expired (25%+ watched or 30 days completed)');
    }

    // 3. Check for existing active refund request
    const existing = await prisma.refundRequest.findFirst({
      where: {
        paymentId,
        status: { in: ['PENDING', 'UNDER_REVIEW', 'APPROVED', 'PROCESSED'] },
      },
    });

    if (existing) {
      throw new Error('An active refund request already exists for this payment');
    }

    // 4. Create RefundRequest record
    const refundRequest = await prisma.refundRequest.create({
      data: {
        userId,
        paymentId,
        snapshotId: snapshot.id,
        amount: payment.amount,
        reason,
        bankDetails: bankDetails || null,
        additionalDetails: additionalDetails || null,
        status: 'PENDING',
      },
    });

    // 5. Create Notification
    await prisma.notification.create({
      data: {
        userId,
        title: 'Refund Request Submitted',
        message: `Your refund request for payment #${payment.orderId.substring(0, 10)} has been submitted and is pending admin review.`,
        type: 'REFUND',
      },
    });

    // 6. Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'REFUND_REQUEST_CREATED',
        details: JSON.stringify({ refundRequestId: refundRequest.id, paymentId, amount: payment.amount }),
      },
    });

    return refundRequest;
  }

  /**
   * Get user's own refund requests
   */
  async getUserRefundRequests(userId) {
    return prisma.refundRequest.findMany({
      where: { userId },
      include: {
        payment: {
          select: {
            id: true,
            orderId: true,
            paymentId: true,
            amount: true,
            createdAt: true,
            product: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Admin: Get all refund requests
   */
  async getAdminRefundRequests({ status, limit = 50, page = 1 }) {
    const where = {};
    if (status) {
      where.status = status;
    }

    const total = await prisma.refundRequest.count({ where });
    const requests = await prisma.refundRequest.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            referralCode: true,
            profile: { select: { firstName: true, lastName: true, phoneNumber: true } },
          },
        },
        payment: {
          select: {
            id: true,
            orderId: true,
            paymentId: true,
            amount: true,
            product: { select: { id: true, name: true } },
          },
        },
        snapshot: true,
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      total,
      page,
      limit,
      requests,
    };
  }

  /**
   * Admin: Review / Approve / Reject / Process Refund Request
   */
  async reviewRefundRequest(adminUserId, requestId, { status, adminRemarks }) {
    const validStatuses = ['UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PROCESSED'];
    if (!validStatuses.includes(status)) {
      throw new Error(`Invalid status target: ${status}`);
    }

    const request = await prisma.refundRequest.findUnique({
      where: { id: requestId },
      include: { payment: true },
    });

    if (!request) {
      throw new Error('Refund request not found');
    }

    // Strict State Machine Transitions:
    // PENDING -> UNDER_REVIEW, APPROVED, REJECTED
    // UNDER_REVIEW -> APPROVED, REJECTED
    // APPROVED -> PROCESSED
    // REJECTED / PROCESSED -> Terminal States
    if (request.status === 'PROCESSED' || request.status === 'REJECTED') {
      throw new Error(`Cannot modify a refund request that is already in terminal state: ${request.status}`);
    }

    if (status === 'PROCESSED' && request.status !== 'APPROVED') {
      throw new Error('Refund request must be APPROVED before being marked PROCESSED');
    }

    const updateData = {
      status,
      adminRemarks: adminRemarks || request.adminRemarks,
      reviewedAt: new Date(),
      reviewedBy: adminUserId,
    };

    if (status === 'PROCESSED') {
      updateData.processedAt = new Date();
      updateData.processedBy = adminUserId;

      // Update payment status to REFUNDED
      await prisma.payment.update({
        where: { id: request.paymentId },
        data: { status: 'REFUNDED' },
      });
    }

    const updated = await prisma.refundRequest.update({
      where: { id: requestId },
      data: updateData,
    });

    // Send Notification to user
    await prisma.notification.create({
      data: {
        userId: request.userId,
        title: `Refund Request ${status.replace('_', ' ')}`,
        message: `Your refund request for ₹${request.amount / 100} is now ${status.replace('_', ' ')}. ${adminRemarks ? 'Remarks: ' + adminRemarks : ''}`,
        type: 'REFUND',
      },
    });

    // Audit Log
    await prisma.auditLog.create({
      data: {
        userId: adminUserId,
        action: `REFUND_${status}`,
        details: JSON.stringify({ refundRequestId: requestId, targetUserId: request.userId, status }),
      },
    });

    return updated;
  }
}

module.exports = new RefundService();
