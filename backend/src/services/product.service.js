const prisma = require('../config/database');

class ProductService {
  async createProduct({ name, code, description, status = 'AVAILABLE' }) {
    if (!name || !code) {
      throw new Error('Product name and code are required');
    }

    const existingName = await prisma.product.findUnique({ where: { name } });
    if (existingName) {
      throw new Error('Product name already exists');
    }

    const existingCode = await prisma.product.findUnique({ where: { code } });
    if (existingCode) {
      throw new Error('Product code already exists');
    }

    return prisma.product.create({
      data: {
        name,
        code,
        description: description || null,
        status,
      },
    });
  }

  async getAllProducts(status) {
    const where = {};
    if (status && status !== 'ALL') {
      where.status = status;
    }

    return prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { videos: true, profiles: true },
        },
      },
    });
  }

  async updateProduct(id, { name, description, status }) {
    const product = await prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new Error('Product not found');
    }

    const updateData = {};
    if (name) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (status) updateData.status = status;

    return prisma.product.update({
      where: { id },
      data: updateData,
    });
  }

  async archiveProduct(id) {
    return this.updateProduct(id, { status: 'ARCHIVED' });
  }

  async assignUserProduct(userId, productId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    if (productId) {
      const product = await prisma.product.findUnique({ where: { id: productId } });
      if (!product) {
        throw new Error('Specified product not found');
      }
    }

    return prisma.profile.update({
      where: { userId },
      data: { assignedProductId: productId || null },
      include: { assignedProduct: true },
    });
  }
}

module.exports = new ProductService();
