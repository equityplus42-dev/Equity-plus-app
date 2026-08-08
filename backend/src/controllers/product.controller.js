const productService = require('../services/product.service');
const ApiResponse = require('../utils/apiResponse');

class ProductController {
  async createProduct(req, res, next) {
    try {
      const { name, code, description, status } = req.body;
      const product = await productService.createProduct({ name, code, description, status });
      return ApiResponse.success(res, 'Product created successfully', product, 201);
    } catch (error) {
      next(error);
    }
  }

  async getAllProducts(req, res, next) {
    try {
      const { status } = req.query;
      const products = await productService.getAllProducts(status);
      return ApiResponse.success(res, 'Products fetched successfully', products);
    } catch (error) {
      next(error);
    }
  }

  async updateProduct(req, res, next) {
    try {
      const { id } = req.params;
      const { name, description, status } = req.body;
      const product = await productService.updateProduct(id, { name, description, status });
      return ApiResponse.success(res, 'Product updated successfully', product);
    } catch (error) {
      next(error);
    }
  }

  async archiveProduct(req, res, next) {
    try {
      const { id } = req.params;
      const product = await productService.archiveProduct(id);
      return ApiResponse.success(res, 'Product archived successfully', product);
    } catch (error) {
      next(error);
    }
  }

  async assignUserProduct(req, res, next) {
    try {
      const { id } = req.params;
      const { productId } = req.body;
      const result = await productService.assignUserProduct(id, productId);
      return ApiResponse.success(res, 'User product assigned successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async getPendingProductAccesses(req, res, next) {
    try {
      const prisma = require('../config/database');
      const accesses = await prisma.userProductAccess.findMany({
        where: { status: 'PENDING_APPROVAL' },
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
          payment: { select: { id: true, orderId: true, amount: true, createdAt: true } },
        },
        orderBy: { createdAt: 'desc' },
      });
      return ApiResponse.success(res, 'Pending product accesses retrieved', accesses);
    } catch (error) {
      next(error);
    }
  }

  async approveProductAccess(req, res, next) {
    try {
      const { id } = req.params;
      const productAccessService = require('../services/productAccess.service');
      const updated = await productAccessService.approveProductAccess(req.user.id, id);
      return ApiResponse.success(res, 'User product access approved and activated', updated);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProductController();
