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

  async requestCashPayment(req, res, next) {
    try {
      const { productId } = req.body;
      const payment = await paymentService.requestCashPayment({
        userId: req.user.id,
        productId,
      });
      return ApiResponse.success(res, 'Cash payment request submitted to Admin', payment, 201);
    } catch (error) {
      next(error);
    }
  }

  async approveCashPayment(req, res, next) {
    try {
      const { paymentId } = req.params;
      const payment = await paymentService.approveCashPayment(paymentId, req.user.id);
      return ApiResponse.success(res, 'Cash payment approved successfully', payment);
    } catch (error) {
      next(error);
    }
  }

  async getPaymentStatus(req, res, next) {
    try {
      const { paymentId } = req.params;
      const status = await paymentService.getPaymentStatus(paymentId, req.user.id);
      return ApiResponse.success(res, 'Payment status retrieved', status);
    } catch (error) {
      next(error);
    }
  }

  async getMembershipPrice(req, res, next) {
    try {
      const price = await paymentService.getMembershipPrice();
      return ApiResponse.success(res, 'Current membership price retrieved', { price });
    } catch (error) {
      next(error);
    }
  }

  async updateMembershipPrice(req, res, next) {
    try {
      const { price } = req.body;
      if (price === undefined || price === null) {
        return ApiResponse.error(res, 'Price is required', 400);
      }
      const result = await paymentService.updateMembershipPrice(price);
      return ApiResponse.success(res, 'Membership price updated successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async resetUserPaymentStatus(req, res, next) {
    try {
      const { userId, email } = req.body;
      const target = userId || email || req.user.id;
      const result = await paymentService.resetUserPaymentStatus(target);
      return ApiResponse.success(res, 'Test user payment status reset successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async bypassPayment(req, res, next) {
    try {
      const { productId } = req.body;
      const result = await paymentService.bypassTestPayment(req.user.id, productId);
      return ApiResponse.success(res, 'Test payment bypassed & full access granted', result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PaymentController();
