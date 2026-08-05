const languageRequestService = require('../services/languageRequest.service');
const ApiResponse = require('../utils/apiResponse');

class LanguageRequestController {
  async createRequest(req, res, next) {
    try {
      const { requestedLanguageId, reason } = req.body;
      const requestRecord = await languageRequestService.createRequest(
        req.user.id,
        requestedLanguageId,
        reason
      );
      return ApiResponse.success(res, 'Language change request submitted successfully', requestRecord, 201);
    } catch (error) {
      next(error);
    }
  }

  async getUserRequests(req, res, next) {
    try {
      const requests = await languageRequestService.getUserRequests(req.user.id);
      return ApiResponse.success(res, 'User language change requests fetched', requests);
    } catch (error) {
      next(error);
    }
  }

  async getAdminRequests(req, res, next) {
    try {
      const { status } = req.query;
      const requests = await languageRequestService.getAdminRequests(status);
      return ApiResponse.success(res, 'Admin language change requests fetched', requests);
    } catch (error) {
      next(error);
    }
  }

  async reviewRequest(req, res, next) {
    try {
      const { id } = req.params;
      const { status, adminRemarks, resetProgressOption } = req.body;
      const updated = await languageRequestService.reviewRequest(
        id,
        req.user.id,
        status,
        adminRemarks,
        resetProgressOption
      );
      return ApiResponse.success(res, `Request ${status.toLowerCase()} successfully`, updated);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LanguageRequestController();
