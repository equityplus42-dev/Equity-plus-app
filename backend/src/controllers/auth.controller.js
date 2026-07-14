const authService = require('../services/auth.service');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');

class AuthController {
  async register(req, res, next) {
    try {
      const result = await authService.register(req.body);
      await auditLogService.log(req, 'REGISTER', result.user.id, { email: result.user.email });
      return ApiResponse.success(res, 'Registration successful', result, 201);
    } catch (error) {
      next(error);
    }
  }

  async login(req, res, next) {
    try {
      const result = await authService.login(req.body);
      await auditLogService.log(req, 'LOGIN', result.user.id, { email: result.user.email });
      return ApiResponse.success(res, 'Login successful', result);
    } catch (error) {
      next(error);
    }
  }

  async logout(req, res, next) {
    try {
      // Client destroys token on their side; we just send a success confirmation
      return ApiResponse.success(res, 'Logout successful');
    } catch (error) {
      next(error);
    }
  }

  async requestPasswordResetOtp(req, res, next) {
    try {
      const { email } = req.body;
      const result = await authService.requestPasswordResetOtp(email);
      return ApiResponse.success(res, result.message, { remainingAttempts: result.remainingAttempts });
    } catch (error) {
      next(error);
    }
  }

  async verifyPasswordResetOtp(req, res, next) {
    try {
      const { email, otp } = req.body;
      const result = await authService.verifyPasswordResetOtp(email, otp);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }

  async resetPassword(req, res, next) {
    try {
      const { email, otp, password } = req.body;
      const result = await authService.resetPassword(email, otp, password);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
