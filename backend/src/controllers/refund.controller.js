const refundService = require('../services/refund.service');
const ApiResponse = require('../utils/apiResponse');

class RefundController {
  async createRefundRequest(req, res, next) {
    try {
      const { paymentId, reason, bankDetails, additionalDetails } = req.body;
      if (!paymentId || !reason) {
        return ApiResponse.error(res, 'paymentId and reason are required', 400);
      }
      const refundRequest = await refundService.createRefundRequest({
        userId: req.user.id,
        paymentId,
        reason,
        bankDetails,
        additionalDetails,
      });
      return ApiResponse.success(res, 'Refund request submitted successfully', refundRequest, 201);
    } catch (error) {
      next(error);
    }
  }

  async getUserRefundRequests(req, res, next) {
    try {
      const requests = await refundService.getUserRefundRequests(req.user.id);
      return ApiResponse.success(res, 'User refund requests retrieved', requests);
    } catch (error) {
      next(error);
    }
  }

  async getAdminRefundRequests(req, res, next) {
    try {
      const { status, limit, page } = req.query;
      const result = await refundService.getAdminRefundRequests({
        status,
        limit: limit ? parseInt(limit, 10) : 50,
        page: page ? parseInt(page, 10) : 1,
      });
      return ApiResponse.success(res, 'Admin refund requests retrieved', result);
    } catch (error) {
      next(error);
    }
  }

  async reviewRefundRequest(req, res, next) {
    try {
      const { id } = req.params;
      const { status, adminRemarks } = req.body;
      if (!status) {
        return ApiResponse.error(res, 'status is required', 400);
      }
      const updated = await refundService.reviewRefundRequest(req.user.id, id, {
        status,
        adminRemarks,
      });
      return ApiResponse.success(res, `Refund request status updated to ${status}`, updated);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new RefundController();
