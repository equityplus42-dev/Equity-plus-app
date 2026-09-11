const crypto = require('crypto');
const prisma = require('../config/database');
const jwtService = require('./jwt.service');
const { AppError, ErrorCodes } = require('../utils/appError');

class PasskeyService {
  /**
   * Lazily loads @simplewebauthn/server (ESM module)
   */
  async _getWebAuthnModule() {
    if (!this._webauthn) {
      this._webauthn = await import('@simplewebauthn/server');
    }
    return this._webauthn;
  }

  /**
   * Resolves RP ID, RP Name, and valid origins based on environment and request
   */
  getWebAuthnConfig(req) {
    const envRpId = process.env.WEBAUTHN_RP_ID;
    const envRpName = process.env.WEBAUTHN_RP_NAME || 'Vridhi Network';

    const reqHost = req?.headers?.host?.split(':')[0];
    let rpID = envRpId || 'vridhi-network-app.vercel.app';
    if (reqHost === 'localhost' || reqHost === '127.0.0.1') {
      rpID = 'localhost';
    }

    const allowedOrigins = [
      'https://vridhi-network-app.vercel.app',
      'https://equity-plus-app.vercel.app',
      // Android APK SHA-256 key hash origin for com.referral.user_app
      'android:apk-key-hash:ba9UbJ6swEnG2jGssTxQq3qPfv9GjPwDOmE0t9uXTCs',
      'http://localhost:3000',
      'http://localhost:5000',
      'http://localhost:5173',
      'http://127.0.0.1:5000',
    ];

    if (process.env.WEBAUTHN_ORIGIN && !allowedOrigins.includes(process.env.WEBAUTHN_ORIGIN)) {
      allowedOrigins.push(process.env.WEBAUTHN_ORIGIN);
    }

    return { rpID, rpName: envRpName, allowedOrigins };
  }

  /**
   * Generates WebAuthn registration options for an authenticated user
   */
  async generateRegistrationOptions({ user, req }) {
    const { generateRegistrationOptions } = await this._getWebAuthnModule();
    const { rpID, rpName } = this.getWebAuthnConfig(req);

    // Fetch existing user passkeys to prevent re-registering on same authenticator
    const existingPasskeys = await prisma.passkeyCredential.findMany({
      where: { userId: user.id },
      select: { credentialId: true, transports: true },
    });

    const excludeCredentials = existingPasskeys.map((p) => ({
      id: p.credentialId,
      transports: p.transports ? p.transports.split(',') : undefined,
    }));

    const options = await generateRegistrationOptions({
      rpName,
      rpID,
      userID: new TextEncoder().encode(user.id),
      userName: user.email,
      userDisplayName: `${user.profile?.firstName || ''} ${user.profile?.lastName || ''}`.trim() || user.email,
      attestationType: 'none',
      excludeCredentials,
      authenticatorSelection: {
        residentKey: 'preferred',
        userVerification: 'preferred',
      },
    });

    // Store challenge with 5-minute expiry in database (Vercel serverless safe)
    await prisma.webAuthnChallenge.create({
      data: {
        challenge: options.challenge,
        userId: user.id,
        type: 'REGISTRATION',
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });

    return options;
  }

  /**
   * Verifies WebAuthn registration response and persists the new PasskeyCredential
   */
  async verifyRegistration({ user, clientResponse, nickname, req }) {
    const { verifyRegistrationResponse } = await this._getWebAuthnModule();
    const { rpID, allowedOrigins } = this.getWebAuthnConfig(req);

    // Extract challenge from clientDataJSON
    let challengeRecord = null;
    try {
      const clientDataJsonStr = Buffer.from(clientResponse.response.clientDataJSON, 'base64url').toString('utf8');
      const clientData = JSON.parse(clientDataJsonStr);
      if (clientData.challenge) {
        challengeRecord = await prisma.webAuthnChallenge.findFirst({
          where: {
            challenge: clientData.challenge,
            userId: user.id,
            type: 'REGISTRATION',
            expiresAt: { gt: new Date() },
          },
        });
      }
    } catch (_) {}

    if (!challengeRecord) {
      // Fallback: look up latest active registration challenge for this user
      challengeRecord = await prisma.webAuthnChallenge.findFirst({
        where: {
          userId: user.id,
          type: 'REGISTRATION',
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (!challengeRecord) {
      throw new AppError('Passkey registration challenge expired or not found. Please try again.', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // Immediately consume challenge (one-time use)
    await prisma.webAuthnChallenge.delete({ where: { id: challengeRecord.id } }).catch(() => {});

    let verification;
    try {
      verification = await verifyRegistrationResponse({
        response: clientResponse,
        expectedChallenge: challengeRecord.challenge,
        expectedOrigin: allowedOrigins,
        expectedRPID: rpID,
        requireUserVerification: false,
      });
    } catch (verifError) {
      throw new AppError(`Passkey verification failed: ${verifError.message}`, 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    if (!verification.verified || !verification.registrationInfo) {
      throw new AppError('Passkey could not be verified by the authenticator', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    const { credential, credentialDeviceType, credentialBackedUp } = verification.registrationInfo;

    // Check if credential ID is already registered
    const existing = await prisma.passkeyCredential.findUnique({
      where: { credentialId: credential.id },
    });
    if (existing) {
      throw new AppError('This passkey is already registered to an account', 400, ErrorCodes.SYSTEM_VALIDATION_ERROR);
    }

    const newPasskey = await prisma.passkeyCredential.create({
      data: {
        userId: user.id,
        credentialId: credential.id,
        publicKey: Buffer.from(credential.publicKey).toString('base64url'),
        counter: BigInt(credential.counter || 0),
        deviceType: credentialDeviceType || 'singleDevice',
        backedUp: credentialBackedUp || false,
        transports: credential.transports ? credential.transports.join(',') : null,
        name: nickname?.trim() || 'My Passkey',
      },
    });

    return {
      id: newPasskey.id,
      name: newPasskey.name,
      deviceType: newPasskey.deviceType,
      backedUp: newPasskey.backedUp,
      createdAt: newPasskey.createdAt,
    };
  }

  /**
   * Generates WebAuthn authentication options (supports discoverable / usernameless flow)
   */
  async generateAuthenticationOptions({ email, req }) {
    const { generateAuthenticationOptions } = await this._getWebAuthnModule();
    const { rpID } = this.getWebAuthnConfig(req);

    let allowCredentials = undefined;
    let userId = null;

    if (email) {
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
        include: { passkeys: true },
      });

      if (user && user.passkeys.length > 0) {
        userId = user.id;
        allowCredentials = user.passkeys.map((p) => ({
          id: p.credentialId,
          transports: p.transports ? p.transports.split(',') : undefined,
        }));
      }
    }

    const options = await generateAuthenticationOptions({
      rpID,
      allowCredentials,
      userVerification: 'preferred',
    });

    // Store challenge with 5-minute expiry in database (Vercel serverless safe)
    await prisma.webAuthnChallenge.create({
      data: {
        challenge: options.challenge,
        userId,
        type: 'AUTHENTICATION',
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });

    return options;
  }

  /**
   * Generates WebAuthn authentication options specifically for password reset.
   * Stores the challenge with type 'RESET_PASSWORD' so it cannot be consumed
   * by a concurrent login verification call.
   */
  async generatePasswordResetOptions({ email, req }) {
    const { generateAuthenticationOptions } = await this._getWebAuthnModule();
    const { rpID } = this.getWebAuthnConfig(req);

    let allowCredentials = undefined;
    let userId = null;

    if (email) {
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
        include: { passkeys: true },
      });

      if (user && user.passkeys.length > 0) {
        userId = user.id;
        allowCredentials = user.passkeys.map((p) => ({
          id: p.credentialId,
          transports: p.transports ? p.transports.split(',') : undefined,
        }));
      }
    }

    const options = await generateAuthenticationOptions({
      rpID,
      allowCredentials,
      userVerification: 'preferred',
    });

    // Store with RESET_PASSWORD type so it is isolated from regular login challenges
    await prisma.webAuthnChallenge.create({
      data: {
        challenge: options.challenge,
        userId,
        type: 'RESET_PASSWORD',
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });

    return options;
  }

  /**
   * Verifies WebAuthn authentication assertion and issues the standard user JWT
   */
  async verifyAuthentication({ clientResponse, req }) {
    const { verifyAuthenticationResponse } = await this._getWebAuthnModule();
    const { rpID, allowedOrigins } = this.getWebAuthnConfig(req);

    if (!clientResponse || !clientResponse.id) {
      throw new AppError('Invalid passkey assertion received', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // 1. Locate the registered credential in database
    const dbPasskey = await prisma.passkeyCredential.findUnique({
      where: { credentialId: clientResponse.id },
      include: {
        user: {
          include: { profile: true },
        },
      },
    });

    if (!dbPasskey || !dbPasskey.user || dbPasskey.user.isDeleted) {
      throw new AppError('Passkey not recognized or account deactivated', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    const user = dbPasskey.user;

    if (!user.isApproved) {
      throw new AppError('Your account is pending admin approval.', 403, ErrorCodes.USER_SUSPENDED);
    }

    if (!user.isActive) {
      throw new AppError('Your account has been suspended by an administrator.', 403, ErrorCodes.USER_SUSPENDED);
    }

    // 2. Extract and match challenge
    let challengeRecord = null;
    try {
      const clientDataJsonStr = Buffer.from(clientResponse.response.clientDataJSON, 'base64url').toString('utf8');
      const clientData = JSON.parse(clientDataJsonStr);
      if (clientData.challenge) {
        challengeRecord = await prisma.webAuthnChallenge.findFirst({
          where: {
            challenge: clientData.challenge,
            type: 'AUTHENTICATION',
            expiresAt: { gt: new Date() },
          },
        });
      }
    } catch (_) {}

    if (!challengeRecord) {
      // Fallback to latest active authentication challenge
      challengeRecord = await prisma.webAuthnChallenge.findFirst({
        where: {
          type: 'AUTHENTICATION',
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (!challengeRecord) {
      throw new AppError('Authentication challenge expired or invalid. Please try again.', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // Immediately consume challenge (one-time use)
    await prisma.webAuthnChallenge.delete({ where: { id: challengeRecord.id } }).catch(() => {});

    // 3. Verify cryptographic assertion
    let verification;
    try {
      verification = await verifyAuthenticationResponse({
        response: clientResponse,
        expectedChallenge: challengeRecord.challenge,
        expectedOrigin: allowedOrigins,
        expectedRPID: rpID,
        credential: {
          id: dbPasskey.credentialId,
          publicKey: Buffer.from(dbPasskey.publicKey, 'base64url'),
          counter: Number(dbPasskey.counter),
          transports: dbPasskey.transports ? dbPasskey.transports.split(',') : undefined,
        },
        requireUserVerification: false,
      });
    } catch (verifError) {
      throw new AppError(`Passkey verification failed: ${verifError.message}`, 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    if (!verification.verified) {
      throw new AppError('Passkey authentication verification failed', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // 4. Update counter and lastUsedAt
    await prisma.passkeyCredential.update({
      where: { id: dbPasskey.id },
      data: {
        counter: BigInt(verification.authenticationInfo.newCounter),
        lastUsedAt: new Date(),
      },
    });

    // 5. Issue standard JWT token via existing JWT pipeline
    const token = jwtService.sign({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    const { password: _, ...userWithoutPassword } = user;
    return {
      user: userWithoutPassword,
      token,
      passkeyUsed: {
        id: dbPasskey.id,
        name: dbPasskey.name,
      },
    };
  }

  /**
   * Verifies WebAuthn assertion specifically for password reset and issues a verified resetToken
   */
  async verifyPasswordReset({ clientResponse, req }) {
    const { verifyAuthenticationResponse } = await this._getWebAuthnModule();
    const { rpID, allowedOrigins } = this.getWebAuthnConfig(req);

    if (!clientResponse || !clientResponse.id) {
      throw new AppError('Invalid passkey assertion received', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // 1. Locate the registered credential in database
    const dbPasskey = await prisma.passkeyCredential.findUnique({
      where: { credentialId: clientResponse.id },
      include: { user: true },
    });

    if (!dbPasskey || !dbPasskey.user || dbPasskey.user.isDeleted) {
      throw new AppError('Passkey not recognized or account deactivated', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    const user = dbPasskey.user;

    // 2. Extract and match challenge (RESET_PASSWORD type only — isolated from login)
    let challengeRecord = null;
    try {
      const clientDataJsonStr = Buffer.from(clientResponse.response.clientDataJSON, 'base64url').toString('utf8');
      const clientData = JSON.parse(clientDataJsonStr);
      if (clientData.challenge) {
        challengeRecord = await prisma.webAuthnChallenge.findFirst({
          where: {
            challenge: clientData.challenge,
            type: 'RESET_PASSWORD',
            expiresAt: { gt: new Date() },
          },
        });
      }
    } catch (_) {}

    if (!challengeRecord) {
      // Fallback: most recent unexpired RESET_PASSWORD challenge
      challengeRecord = await prisma.webAuthnChallenge.findFirst({
        where: {
          type: 'RESET_PASSWORD',
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (!challengeRecord) {
      throw new AppError('Verification challenge expired or invalid. Please try again.', 400, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // Immediately consume challenge
    await prisma.webAuthnChallenge.delete({ where: { id: challengeRecord.id } }).catch(() => {});

    // 3. Verify cryptographic assertion
    let verification;
    try {
      verification = await verifyAuthenticationResponse({
        response: clientResponse,
        expectedChallenge: challengeRecord.challenge,
        expectedOrigin: allowedOrigins,
        expectedRPID: rpID,
        credential: {
          id: dbPasskey.credentialId,
          publicKey: Buffer.from(dbPasskey.publicKey, 'base64url'),
          counter: Number(dbPasskey.counter),
          transports: dbPasskey.transports ? dbPasskey.transports.split(',') : undefined,
        },
        requireUserVerification: false,
      });
    } catch (verifError) {
      throw new AppError(`Passkey verification failed: ${verifError.message}`, 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    if (!verification.verified) {
      throw new AppError('Passkey verification failed', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // 4. Update counter and lastUsedAt
    await prisma.passkeyCredential.update({
      where: { id: dbPasskey.id },
      data: {
        counter: BigInt(verification.authenticationInfo.newCounter),
        lastUsedAt: new Date(),
      },
    });

    // 5. Generate secure one-time password reset token
    const resetToken = crypto.randomBytes(32).toString('hex');

    await prisma.user.update({
      where: { id: user.id },
      data: {
        otpCode: resetToken,
        otpExpiresAt: new Date(Date.now() + 15 * 60 * 1000), // 15 mins validity
      },
    });

    return {
      email: user.email,
      resetToken,
      passkeyName: dbPasskey.name,
    };
  }

  /**
   * Lists all passkeys registered to a user
   */
  async listUserPasskeys(userId) {
    const passkeys = await prisma.passkeyCredential.findMany({
      where: { userId },
      select: {
        id: true,
        name: true,
        deviceType: true,
        backedUp: true,
        createdAt: true,
        lastUsedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return passkeys;
  }

  /**
   * Deletes a passkey (enforces safety checks to prevent account lockout)
   */
  async deletePasskey(userId, passkeyId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { passkeys: true },
    });

    if (!user) {
      throw new AppError('User not found', 404, ErrorCodes.USER_NOT_FOUND);
    }

    const passkey = user.passkeys.find((p) => p.id === passkeyId);
    if (!passkey) {
      throw new AppError('Passkey not found', 404, ErrorCodes.SYSTEM_NOT_FOUND);
    }

    const hasPassword = Boolean(user.password && user.password.length > 0);
    if (!hasPassword && user.passkeys.length <= 1) {
      throw new AppError(
        'Cannot delete your only authentication method. Please set a password or register another passkey first.',
        400,
        ErrorCodes.SYSTEM_VALIDATION_ERROR
      );
    }

    await prisma.passkeyCredential.delete({
      where: { id: passkeyId },
    });

    return { success: true, message: 'Passkey deleted successfully' };
  }

  /**
   * Updates passkey nickname
   */
  async renamePasskey(userId, passkeyId, newName) {
    const passkey = await prisma.passkeyCredential.findFirst({
      where: { id: passkeyId, userId },
    });

    if (!passkey) {
      throw new AppError('Passkey not found', 404, ErrorCodes.SYSTEM_NOT_FOUND);
    }

    const updated = await prisma.passkeyCredential.update({
      where: { id: passkeyId },
      data: { name: newName.trim() },
      select: {
        id: true,
        name: true,
        deviceType: true,
        lastUsedAt: true,
        createdAt: true,
      },
    });

    return updated;
  }
}

module.exports = new PasskeyService();
