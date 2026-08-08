const prisma = require('../config/database');
const razorpayConfig = require('../config/razorpay');
const { v4: uuidv4 } = require('uuid');

class PaymentService {
  /**
   * Create Razorpay Order server-side
   */
  async createOrder({ userId, productId }) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      throw new Error('Product not found');
    }

    if (product.status !== 'AVAILABLE') {
      throw new Error('Product is not currently available for purchase');
    }

    // Determine amount server-side in paise (1 INR = 100 paise)
    const amountInPaise = (product.price || 1000) * 100;
    const orderId = `order_${uuidv4().substring(0, 14)}`;

    // Create local Payment record in CREATED state
    const payment = await prisma.payment.create({
      data: {
        userId,
        productId,
        orderId,
        amount: amountInPaise,
        currency: 'INR',
        status: 'CREATED',
      },
    });

    // Create Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'PAYMENT_ORDER_CREATED',
        details: JSON.stringify({ orderId, productId, amountInPaise }),
      },
    });

    return {
      paymentId: payment.id,
      orderId: payment.orderId,
      amount: payment.amount,
      currency: payment.currency,
      keyId: razorpayConfig.keyId,
      product: {
        id: product.id,
        name: product.name,
        description: product.description,
      },
    };
  }

  /**
   * Verify Razorpay Payment Signature
   */
  async verifyPayment({ userId, orderId, paymentId, signature }) {
    const payment = await prisma.payment.findUnique({
      where: { orderId },
      include: { product: true },
    });

    if (!payment) {
      throw new Error('Payment record not found for this order ID');
    }

    if (payment.userId !== userId) {
      throw new Error('Unauthorized payment verification attempt');
    }

    const isValidSignature = razorpayConfig.verifySignature(orderId, paymentId, signature);

    if (!isValidSignature) {
      await prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: 'VERIFICATION_FAILED',
          failureReason: 'Invalid Razorpay HMAC signature',
        },
      });

      await prisma.auditLog.create({
        data: {
          userId,
          action: 'PAYMENT_VERIFICATION_FAILED',
          details: JSON.stringify({ orderId, paymentId }),
        },
      });

      throw new Error('Payment verification failed due to invalid signature');
    }

    // Mark payment SUCCESS
    const updatedPayment = await prisma.payment.update({
      where: { id: payment.id },
      data: {
        paymentId,
        signature,
        status: 'SUCCESS',
        verifiedAt: new Date(),
      },
    });

    // Create UserProductAccess in PENDING_APPROVAL status (waiting for admin approval)
    const existingAccess = await prisma.userProductAccess.findFirst({
      where: {
        userId,
        productId: payment.productId,
      },
    });

    let productAccess;
    if (existingAccess) {
      productAccess = await prisma.userProductAccess.update({
        where: { id: existingAccess.id },
        data: {
          paymentId: updatedPayment.id,
          status: 'PENDING_APPROVAL',
        },
      });
    } else {
      productAccess = await prisma.userProductAccess.create({
        data: {
          userId,
          productId: payment.productId,
          paymentId: updatedPayment.id,
          status: 'PENDING_APPROVAL',
        },
      });
    }

    // Notification for user
    await prisma.notification.create({
      data: {
        userId,
        title: 'Payment Successful',
        message: `Your payment of ₹${payment.amount / 100} for "${payment.product.name}" was successful! Waiting for admin approval.`,
        type: 'PAYMENT',
      },
    });

    // Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'PAYMENT_VERIFIED',
        details: JSON.stringify({ orderId, paymentId, productId: payment.productId }),
      },
    });

    return {
      payment: updatedPayment,
      productAccess,
    };
  }

  /**
   * Get payments for current user
   */
  async getUserPayments(userId) {
    return prisma.payment.findMany({
      where: { userId },
      include: {
        product: { select: { id: true, name: true, code: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Admin: Get global payments list
   */
  async getAdminPayments({ status, search, limit = 50, page = 1 }) {
    const where = {};
    if (status) {
      where.status = status;
    }
    if (search) {
      where.OR = [
        { orderId: { contains: search } },
        { paymentId: { contains: search } },
        { user: { email: { contains: search } } },
      ];
    }

    const total = await prisma.payment.count({ where });
    const payments = await prisma.payment.findMany({
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
        product: { select: { id: true, name: true, code: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      total,
      page,
      limit,
      payments,
    };
  }
}

module.exports = new PaymentService();
