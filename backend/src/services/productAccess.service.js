const prisma = require('../config/database');

class ProductAccessService {
  /**
   * Admin approves user product access -> status becomes ACTIVE
   */
  async approveProductAccess(adminUserId, userProductAccessId) {
    const access = await prisma.userProductAccess.findUnique({
      where: { id: userProductAccessId },
      include: { product: true },
    });

    if (!access) {
      throw new Error('User product access record not found');
    }

    const updated = await prisma.userProductAccess.update({
      where: { id: userProductAccessId },
      data: {
        status: 'ACTIVE',
        approvedAt: new Date(),
        approvedBy: adminUserId,
      },
    });

    // Update Profile assignedProduct
    await prisma.profile.updateMany({
      where: { userId: access.userId },
      data: { assignedProductId: access.productId },
    });

    // Send notification
    await prisma.notification.create({
      data: {
        userId: access.userId,
        title: 'Product Access Approved',
        message: `Your product access for "${access.product.name}" has been approved and activated!`,
        type: 'SYSTEM',
      },
    });

    // Audit log
    await prisma.auditLog.create({
      data: {
        userId: adminUserId,
        action: 'PRODUCT_ACCESS_APPROVED',
        details: JSON.stringify({ userProductAccessId, targetUserId: access.userId, productId: access.productId }),
      },
    });

    return updated;
  }

  /**
   * Verify server-side if user has active access to product
   */
  async hasActiveAccess(userId, productId) {
    if (!productId) return true;
    const access = await prisma.userProductAccess.findFirst({
      where: {
        userId,
        productId,
        status: 'ACTIVE',
      },
    });
    return !!access;
  }
}

module.exports = new ProductAccessService();
