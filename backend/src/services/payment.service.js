const prisma = require('../config/database');
const razorpayConfig = require('../config/razorpay');
const { randomUUID: uuidv4 } = require('crypto');

class PaymentService {
  /**
   * Create Razorpay Order server-side
   */
  async createOrder({ userId, productId }) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    let product = await prisma.product.findUnique({ where: { id: productId } }).catch(() => null);
    if (!product) {
      product = await prisma.product.findFirst({ where: { status: 'AVAILABLE' } });
      if (!product) {
        product = await prisma.product.create({
          data: {
            name: 'Vridhi Network Membership',
            code: 'MEMBERSHIP_VIP',
            price: 1,
            status: 'AVAILABLE',
            description: 'Full membership access with referral tree and exclusive learning material.',
          },
        });
      }
    }

    // Determine amount server-side in paise (1 INR = 100 paise)
    const priceSetting = await prisma.systemSettings.findUnique({ where: { key: 'membership_price_inr' } }).catch(() => null);
    let priceInRupees = priceSetting ? parseInt(priceSetting.value, 10) : (product.price || 1);
    if (!priceInRupees || isNaN(priceInRupees) || priceInRupees <= 0) priceInRupees = 1;

    const amountInPaise = priceInRupees * 100;
    let orderId = `order_${uuidv4().substring(0, 14)}`;

    // Try creating real Razorpay order via Razorpay API if configured
    if (razorpayConfig.isConfigured()) {
      try {
        const authHeader = 'Basic ' + Buffer.from(`${razorpayConfig.keyId}:${razorpayConfig.keySecret}`).toString('base64');
        const res = await fetch('https://api.razorpay.com/v1/orders', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: JSON.stringify({
            amount: amountInPaise,
            currency: 'INR',
            receipt: `rcpt_${uuidv4().substring(0, 10)}`,
          }),
        });

        if (res.ok) {
          const rzpData = await res.json();
          if (rzpData && rzpData.id) {
            orderId = rzpData.id;
          }
        } else {
          const errText = await res.text();
          console.warn('[Razorpay API Warning] Could not create Razorpay order:', errText);
        }
      } catch (rzpErr) {
        console.warn('[Razorpay API Exception] Order creation fallback to local:', rzpErr.message);
      }
    }

    // Create local Payment record in CREATED state
    const payment = await prisma.payment.create({
      data: {
        userId,
        productId: product.id,
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

    // Notify Admin app about new user registration & payment transaction
    const notificationService = require('./notification.service');
    const userDetail = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });
    const userName = userDetail?.profile?.firstName
      ? `${userDetail.profile.firstName} ${userDetail.profile.lastName || ''}`.trim()
      : userDetail?.email || 'User';
    const isBypassed = signature === 'demo_bypass' || signature === 'bypass';
    await notificationService.notifyAdmins(
      'New User Registration & Payment 🎉',
      `User ${userName} (${userDetail?.email}) registered with referral code "${userDetail?.referralCode || 'N/A'}" and completed transaction of ₹${payment.amount / 100} (${isBypassed ? 'Demo Bypassed' : 'Razorpay Verified'}). Order ID: ${orderId}.`,
      'PAYMENT',
      userId
    );

    // Audit Log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'PAYMENT_VERIFIED',
        details: JSON.stringify({ orderId, paymentId, productId: payment.productId, isBypassed }),
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
    const testUserFilter = {
      isTestUser: false,
      email: { not: 'test@gmail.com' },
    };

    const where = {
      user: testUserFilter,
    };

    if (status) {
      where.status = status;
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      where.AND = [
        { user: testUserFilter },
        {
          OR: [
            { orderId: { contains: q } },
            { paymentId: { contains: q } },
            { user: { email: { contains: q } } },
          ],
        },
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

  /**
   * Request Cash Payment (User option: Paid in Cash)
   */
  async requestCashPayment({ userId, productId }) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });
    if (!user) {
      throw new Error('User not found');
    }

    let product = await prisma.product.findUnique({ where: { id: productId } }).catch(() => null);
    if (!product) {
      product = await prisma.product.findFirst({ where: { status: 'AVAILABLE' } });
      if (!product) {
        product = await prisma.product.create({
          data: {
            name: 'Vridhi Network Membership',
            code: 'MEMBERSHIP_VIP',
            price: 1000,
            status: 'AVAILABLE',
            description: 'Full membership access with referral tree and exclusive learning material.',
          },
        });
      }
    }

    // Check if there is already a pending cash payment request for this user
    const existingPending = await prisma.payment.findFirst({
      where: {
        userId,
        status: 'PENDING_CASH_APPROVAL',
      },
    });

    if (existingPending) {
      return existingPending;
    }

    const amountInPaise = (product.price || 1000) * 100;
    const orderId = `cash_ord_${uuidv4().substring(0, 14)}`;
    const paymentId = `cash_pay_${uuidv4().substring(0, 14)}`;

    const payment = await prisma.payment.create({
      data: {
        userId,
        productId: product.id,
        orderId,
        paymentId,
        amount: amountInPaise,
        currency: 'INR',
        status: 'PENDING_CASH_APPROVAL',
      },
    });

    const userName = user?.profile?.firstName
      ? `${user.profile.firstName} ${user.profile.lastName || ''}`.trim()
      : user.email;

    const notificationService = require('./notification.service');
    await notificationService.notifyAdmins(
      'Cash Payment Request 💵',
      `User "${userName}" (${user.email}) requested Cash Payment approval of ₹${payment.amount / 100} for product "${product.name}". Payment ID: ${payment.id}`,
      'CASH_PAYMENT_REQUEST',
      userId
    );

    await prisma.auditLog.create({
      data: {
        userId,
        action: 'CASH_PAYMENT_REQUESTED',
        details: JSON.stringify({ paymentId: payment.id, orderId, amountInPaise }),
      },
    });

    return payment;
  }

  /**
   * Admin approves cash payment
   */
  async approveCashPayment(paymentId, adminId) {
    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: { product: true, user: { include: { profile: true } } },
    });

    if (!payment) {
      throw new Error('Payment record not found');
    }

    if (payment.status === 'SUCCESS') {
      return payment;
    }

    const updatedPayment = await prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: 'SUCCESS',
        verifiedAt: new Date(),
        signature: 'cash_admin_approved',
      },
    });

    // Create / Update Product Access
    const existingAccess = await prisma.userProductAccess.findFirst({
      where: {
        userId: payment.userId,
        productId: payment.productId,
      },
    });

    if (existingAccess) {
      await prisma.userProductAccess.update({
        where: { id: existingAccess.id },
        data: {
          paymentId: updatedPayment.id,
          status: 'PENDING_APPROVAL',
        },
      });
    } else {
      await prisma.userProductAccess.create({
        data: {
          userId: payment.userId,
          productId: payment.productId,
          paymentId: updatedPayment.id,
          status: 'PENDING_APPROVAL',
        },
      });
    }

    // Send user notification
    await prisma.notification.create({
      data: {
        userId: payment.userId,
        title: 'Cash Payment Approved 🎉',
        message: `Your cash payment of ₹${payment.amount / 100} has been verified and approved by the Admin! Welcome to Vridhi Network.`,
        type: 'PAYMENT',
      },
    });

    // Mark admin cash notification as read
    await prisma.notification.updateMany({
      where: {
        message: { contains: paymentId },
        type: 'CASH_PAYMENT_REQUEST',
      },
      data: {
        isRead: true,
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: adminId,
        action: 'CASH_PAYMENT_APPROVED',
        details: JSON.stringify({ paymentId: payment.id, targetUserId: payment.userId }),
      },
    });

    return updatedPayment;
  }

  /**
   * Check status of a specific payment
   */
  async getPaymentStatus(paymentId, userId) {
    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
    });

    if (!payment) {
      throw new Error('Payment record not found');
    }

    if (payment.userId !== userId) {
      throw new Error('Unauthorized status check');
    }

    return {
      id: payment.id,
      status: payment.status,
      amount: payment.amount,
      updatedAt: payment.updatedAt,
    };
  }

  /**
   * Get current global membership payment amount in INR
   */
  async getMembershipPrice() {
    const setting = await prisma.systemSettings.findUnique({ where: { key: 'membership_price_inr' } }).catch(() => null);
    if (setting && setting.value) {
      const val = parseInt(setting.value, 10);
      if (!isNaN(val) && val > 0) return val;
    }
    const product = await prisma.product.findFirst({ where: { status: 'AVAILABLE' } });
    return product ? (product.price || 1) : 1;
  }

  /**
   * Developer / Admin: Update global membership payment amount
   */
  async updateMembershipPrice(newPriceInRupees) {
    const price = Math.max(1, parseInt(newPriceInRupees, 10) || 1);

    await prisma.systemSettings.upsert({
      where: { key: 'membership_price_inr' },
      update: { value: String(price) },
      create: {
        key: 'membership_price_inr',
        value: String(price),
        description: 'Global Membership Payment Amount in INR',
      },
    });

    await prisma.product.updateMany({
      data: { price },
    });

    return { price };
  }

  /**
   * Developer / Admin: Reset payment status for test user
   */
  async resetUserPaymentStatus(userIdentifier) {
    let user;
    if (userIdentifier) {
      user = await prisma.user.findFirst({
        where: {
          OR: [
            { id: userIdentifier },
            { email: userIdentifier },
          ],
        },
      });
    }

    if (!user) {
      throw new Error('User not found for payment status reset');
    }

    await prisma.userProductAccess.deleteMany({
      where: { userId: user.id },
    });

    await prisma.payment.deleteMany({
      where: { userId: user.id },
    });

    await prisma.refundRequest.deleteMany({
      where: { userId: user.id },
    });

    await prisma.profile.updateMany({
      where: { userId: user.id },
      data: { assignedProductId: null },
    });

    await prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'TEST_PAYMENT_STATUS_RESET',
        details: JSON.stringify({ resetUserId: user.id, email: user.email }),
      },
    });

    return {
      userId: user.id,
      email: user.email,
      message: `Payment status reset successfully for ${user.email}. User can now perform fresh Razorpay payment test.`,
    };
  }

  async bypassTestPayment(userId, productId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found for payment bypass');
    }

    let targetProductId = productId;
    if (!targetProductId) {
      const defaultProduct = await prisma.product.findFirst({ where: { status: 'ACTIVE' } });
      targetProductId = defaultProduct ? defaultProduct.id : null;
    }

    const payment = await prisma.payment.create({
      data: {
        userId: user.id,
        productId: targetProductId,
        amount: 999.00,
        currency: 'INR',
        status: 'SUCCESS',
        paymentMethod: 'TEST_BYPASS',
        razorpayOrderId: `TEST_ORDER_${Date.now()}`,
        razorpayPaymentId: `TEST_PAY_${Date.now()}`,
      },
    });

    if (targetProductId) {
      await prisma.userProductAccess.upsert({
        where: { userId_productId: { userId: user.id, productId: targetProductId } },
        update: { status: 'ACTIVE', paymentId: payment.id },
        create: {
          userId: user.id,
          productId: targetProductId,
          paymentId: payment.id,
          status: 'ACTIVE',
        },
      });

      await prisma.profile.updateMany({
        where: { userId: user.id },
        data: { assignedProductId: targetProductId },
      });
    }

    // Trigger video snapshot so course videos unlock immediately
    const videoService = require('./video.service');
    await videoService.getUserVideos(user.id, { triggerSnapshot: true });

    await prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'PAYMENT_TEST_BYPASS',
        details: JSON.stringify({ paymentId: payment.id, productId: targetProductId }),
      },
    });

    return {
      paymentId: payment.id,
      status: 'SUCCESS',
      paymentMethod: 'TEST_BYPASS',
      message: 'Test payment bypassed successfully & full course access unlocked!',
    };
  }
}

module.exports = new PaymentService();
