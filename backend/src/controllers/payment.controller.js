const paymentService = require('../services/payment.service');
const ApiResponse = require('../utils/apiResponse');

class PaymentController {
  async createOrder(req, res, next) {
    try {
      const { productId } = req.body;
      if (!productId) {
        return ApiResponse.error(res, 'productId is required', 400);
      }
      const order = await paymentService.createOrder({
        userId: req.user.id,
        productId,
      });
      return ApiResponse.success(res, 'Payment order created', order, 201);
    } catch (error) {
      next(error);
    }
  }

  async verifyPayment(req, res, next) {
    try {
      const { orderId, paymentId, signature } = req.body;
      if (!orderId || !paymentId || !signature) {
        return ApiResponse.error(res, 'orderId, paymentId, and signature are required', 400);
      }
      const result = await paymentService.verifyPayment({
        userId: req.user.id,
        orderId,
        paymentId,
        signature,
      });
      return ApiResponse.success(res, 'Payment verified successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async getUserPayments(req, res, next) {
    try {
      const payments = await paymentService.getUserPayments(req.user.id);
      return ApiResponse.success(res, 'User payments retrieved', payments);
    } catch (error) {
      next(error);
    }
  }

  async getAdminPayments(req, res, next) {
    try {
      const { status, search, limit, page } = req.query;
      const result = await paymentService.getAdminPayments({
        status,
        search,
        limit: limit ? parseInt(limit, 10) : 50,
        page: page ? parseInt(page, 10) : 1,
      });
      return ApiResponse.success(res, 'Admin payments list retrieved', result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PaymentController();
