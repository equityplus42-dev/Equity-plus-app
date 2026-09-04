const prisma = require('../config/database');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');
const videoService = require('../services/video.service');
const { hashPassword } = require('../utils/encryption');

class DeveloperController {
  /**
   * Permanently kill and purge the test user (test@gmail.com) and all related records from the database
   */
  async killTestUser(req, res, next) {
    try {
      const testUsers = await prisma.user.findMany({
        where: {
          OR: [
            { email: 'test@gmail.com' },
            { isTestUser: true }
          ]
        }
      });

      if (testUsers.length === 0) {
        return ApiResponse.success(res, 'No active test user (test@gmail.com) found in database.');
      }

      let killedCount = 0;
      for (const u of testUsers) {
        // Delete all child relational data
        await prisma.userVideoProgress.deleteMany({ where: { userId: u.id } });
        
        const snapshot = await prisma.userVideoSnapshot.findUnique({ where: { userId: u.id } });
        if (snapshot) {
          await prisma.snapshotVideo.deleteMany({ where: { snapshotId: snapshot.id } });
          await prisma.userVideoSnapshot.delete({ where: { id: snapshot.id } });
        }
        
        await prisma.videoAssignment.deleteMany({ where: { userId: u.id } });
        await prisma.userProductAccess.deleteMany({ where: { userId: u.id } });
        await prisma.payment.deleteMany({ where: { userId: u.id } });
        await prisma.referral.deleteMany({
          where: { OR: [{ refereeId: u.id }, { referrerId: u.id }] }
        });
        await prisma.hierarchyNode.deleteMany({ where: { userId: u.id } });
        await prisma.profile.deleteMany({ where: { userId: u.id } });
        await prisma.notification.deleteMany({ where: { userId: u.id } });
        await prisma.auditLog.deleteMany({ where: { userId: u.id } });

        // Hard delete the test User row
        await prisma.user.delete({ where: { id: u.id } });
        killedCount++;
      }

      await auditLogService.log(req, 'TEST_USER_KILLED', null, {
        killedCount,
        email: 'test@gmail.com',
        adminId: req.user?.id || 'DEVELOPER'
      });

      return ApiResponse.success(
        res,
        `Test user test@gmail.com (${killedCount}) permanently killed and purged from database successfully!`
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Re-create / reseed clean test@gmail.com Test User (Password: test12,.)
   */
  async reseedTestUser(req, res, next) {
    try {
      const testEmail = 'test@gmail.com';
      const existing = await prisma.user.findUnique({ where: { email: testEmail } });

      if (existing) {
        // Ensure isTestUser = true
        const updated = await prisma.user.update({
          where: { id: existing.id },
          data: { isTestUser: true, isApproved: true, isActive: true },
          include: { profile: true }
        });
        return ApiResponse.success(res, 'Test user test@gmail.com exists and has been reset.', updated);
      }

      const testPasswordHash = await hashPassword('test12,.');
      const testUser = await prisma.user.create({
        data: {
          id: '00000000-0000-0000-0000-000000000002',
          email: testEmail,
          password: testPasswordHash,
          role: 'USER',
          referralCode: 'TESTUSER99',
          isApproved: true,
          isActive: true,
          isTestUser: true,
          profile: {
            create: {
              firstName: 'Test',
              lastName: 'User',
              phoneNumber: '+1999999999',
              bio: 'Isolated Developer Test Account for Payment Bypass & Flow Testing.'
            }
          }
        },
        include: { profile: true }
      });

      await auditLogService.log(req, 'TEST_USER_RESEEDED', testUser.id, {
        email: testUser.email,
        adminId: req.user?.id || 'DEVELOPER'
      });

      return ApiResponse.success(res, 'Clean Test User test@gmail.com re-created in database successfully!', {
        email: testUser.email,
        password: 'test12,.',
        referralCode: testUser.referralCode
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Grant instant payment bypass for test@gmail.com Test User
   */
  async bypassPaymentForTestUser(req, res, next) {
    try {
      let testUser = await prisma.user.findFirst({
        where: { OR: [{ email: 'test@gmail.com' }, { isTestUser: true }] }
      });

      if (!testUser) {
        // Auto-recreate test@gmail.com if killed
        const testPasswordHash = await hashPassword('test12,.');
        testUser = await prisma.user.create({
          data: {
            id: '00000000-0000-0000-0000-000000000002',
            email: 'test@gmail.com',
            password: testPasswordHash,
            role: 'USER',
            referralCode: 'TESTUSER99',
            isApproved: true,
            isActive: true,
            isTestUser: true,
            profile: {
              create: {
                firstName: 'Test',
                lastName: 'User',
                phoneNumber: '+1999999999',
                bio: 'Isolated Developer Test Account.'
              }
            }
          }
        });
      }

      const nowTs = Date.now();
      const orderId = `order_TEST_${nowTs}`;
      const paymentIdStr = `pay_demo_bypass_${nowTs}`;

      const defaultProduct = await prisma.product.findFirst({ where: { status: 'ACTIVE' } }) ||
        await prisma.product.findFirst();

      // Create dummy approved payment record
      const payment = await prisma.payment.create({
        data: {
          userId: testUser.id,
          productId: defaultProduct?.id || null,
          orderId,
          paymentId: paymentIdStr,
          amount: defaultProduct?.pricePaise || 999900,
          currency: 'INR',
          status: 'SUCCESS',
          verifiedAt: new Date(),
        }
      });

      // Grant product access
      if (defaultProduct) {
        const existingAccess = await prisma.userProductAccess.findFirst({
          where: { userId: testUser.id, productId: defaultProduct.id }
        });

        if (existingAccess) {
          await prisma.userProductAccess.update({
            where: { id: existingAccess.id },
            data: { status: 'ACTIVE', paymentId: payment.id }
          });
        } else {
          await prisma.userProductAccess.create({
            data: {
              userId: testUser.id,
              productId: defaultProduct.id,
              paymentId: payment.id,
              status: 'ACTIVE'
            }
          });
        }
      }

      // Ensure snapshot is null for test user so all videos remain dynamically unlocked
      const existingSnapshot = await prisma.userVideoSnapshot.findUnique({ where: { userId: testUser.id } });
      if (existingSnapshot) {
        await prisma.snapshotVideo.deleteMany({ where: { snapshotId: existingSnapshot.id } });
        await prisma.userVideoSnapshot.delete({ where: { id: existingSnapshot.id } });
      }

      await videoService.getUserVideos(testUser.id);

      await auditLogService.log(req, 'TEST_USER_PAYMENT_BYPASSED', testUser.id, {
        paymentId: payment.id,
        email: testUser.email,
        adminId: req.user?.id || 'DEVELOPER'
      });

      return ApiResponse.success(res, 'Payment bypassed & full course access unlocked for test@gmail.com! ⚡', {
        userId: testUser.id,
        email: testUser.email,
        orderId,
        paymentId: paymentIdStr,
        paymentStatus: 'SUCCESS',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get status details of test@gmail.com Test User
   */
  async getTestUserStatus(req, res, next) {
    try {
      const testUser = await prisma.user.findFirst({
        where: { OR: [{ email: 'test@gmail.com' }, { isTestUser: true }] },
        include: {
          profile: true,
          productAccesses: { include: { product: true } },
          payments: { orderBy: { createdAt: 'desc' }, take: 3 },
          videoSnapshot: true
        }
      });

      if (!testUser) {
        return ApiResponse.success(res, 'Test user status fetched', {
          exists: false,
          user: null
        });
      }

      return ApiResponse.success(res, 'Test user status fetched', {
        exists: true,
        user: {
          id: testUser.id,
          email: testUser.email,
          referralCode: testUser.referralCode,
          isTestUser: testUser.isTestUser,
          hasProductAccess: testUser.productAccesses.some(pa => pa.status === 'ACTIVE'),
          hasVideoSnapshot: Boolean(testUser.videoSnapshot),
          recentPayments: testUser.payments
        }
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new DeveloperController();
