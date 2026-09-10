const passkeyService = require('../services/passkey.service');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');

class PasskeyController {
  /**
   * POST /api/v1/auth/passkey/register/options
   * Generate WebAuthn registration options for current user
   */
  async generateRegistrationOptions(req, res, next) {
    try {
      const options = await passkeyService.generateRegistrationOptions({
        user: req.user,
        req,
      });
      return ApiResponse.success(res, 'Passkey registration options generated', options);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/passkey/register/verify
   * Verify WebAuthn registration attestation
   */
  async verifyRegistration(req, res, next) {
    try {
      const { response, name } = req.body;
      const result = await passkeyService.verifyRegistration({
        user: req.user,
        clientResponse: response,
        nickname: name,
        req,
      });

      auditLogService.log(req, 'PASSKEY_REGISTER', req.user.id, { passkeyId: result.id, name: result.name }).catch(() => {});
      return ApiResponse.success(res, 'Passkey successfully registered', result, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/passkey/login/options
   * Generate WebAuthn authentication options (supports discoverable / resident keys)
   */
  async generateAuthenticationOptions(req, res, next) {
    try {
      const { email } = req.body || {};
      const options = await passkeyService.generateAuthenticationOptions({
        email,
        req,
      });
      return ApiResponse.success(res, 'Passkey authentication options generated', options);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/passkey/login/verify
   * Verify WebAuthn assertion and log user in with standard JWT
   */
  async verifyAuthentication(req, res, next) {
    try {
      const { response } = req.body;
      const result = await passkeyService.verifyAuthentication({
        clientResponse: response,
        req,
      });

      auditLogService.log(req, 'PASSKEY_LOGIN', result.user.id, { email: result.user.email, passkeyId: result.passkeyUsed?.id }).catch(() => {});
      return ApiResponse.success(res, 'Passkey login successful', result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/auth/passkey/reset-password/verify
   * Verify WebAuthn assertion for password reset and issue a verified reset token
   */
  async verifyPasswordReset(req, res, next) {
    try {
      const { response } = req.body;
      const result = await passkeyService.verifyPasswordReset({
        clientResponse: response,
        req,
      });

      auditLogService.log(req, 'PASSKEY_PASSWORD_RESET_VERIFIED', null, { email: result.email }).catch(() => {});
      return ApiResponse.success(res, 'Passkey identity verified successfully', result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/passkey/credentials
   * List all passkeys registered to the current authenticated user
   */
  async listPasskeys(req, res, next) {
    try {
      const passkeys = await passkeyService.listUserPasskeys(req.user.id);
      return ApiResponse.success(res, 'Passkeys fetched successfully', passkeys);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/v1/auth/passkey/credentials/:id
   * Delete a passkey credential
   */
  async deletePasskey(req, res, next) {
    try {
      const result = await passkeyService.deletePasskey(req.user.id, req.params.id);
      auditLogService.log(req, 'PASSKEY_DELETE', req.user.id, { passkeyId: req.params.id }).catch(() => {});
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/v1/auth/passkey/credentials/:id
   * Rename a passkey credential
   */
  async renamePasskey(req, res, next) {
    try {
      const { name } = req.body;
      if (!name || !name.trim()) {
        return ApiResponse.error(res, 'Name is required', 400);
      }
      const updated = await passkeyService.renamePasskey(req.user.id, req.params.id, name);
      return ApiResponse.success(res, 'Passkey renamed successfully', updated);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PasskeyController();
