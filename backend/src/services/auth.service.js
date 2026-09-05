const authRepository = require('../repositories/auth.repository');
const userValidator = require('../validators/auth.validator');
const generateCode = require('./referral/generateCode');
const generateLink = require('./referral/generateLink');
const { generateQR } = require('./qr.service');
const { hashPassword, comparePassword } = require('../utils/encryption');
const jwtService = require('./jwt.service');
const hierarchyService = require('./hierarchy.service');
const referralService = require('./referral.service');
const prisma = require('../config/database');
const { sendOtpEmail } = require('../utils/mailer');
const { AppError, ErrorCodes } = require('../utils/appError');

class AuthService {
  /**
   * Register a new user
   */
  async register({ email, password, referralCode, firstName, lastName, phoneNumber, preferredLanguageId }) {
    // 1. Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      if (existingUser.isDeleted) {
        // User was soft-deleted previously. Purge old deleted record so they can re-register cleanly
        await this.purgeDeletedUser(existingUser.id);
      } else {
        throw new AppError('Email is already registered', 400, ErrorCodes.USER_EMAIL_EXISTS);
      }
    }

    // 2. Validate preferred language
    if (!preferredLanguageId) {
      throw new AppError('Preferred language is required', 400, ErrorCodes.SYSTEM_VALIDATION_ERROR);
    }
    const lang = await prisma.language.findUnique({ where: { id: preferredLanguageId } });
    if (!lang) {
      throw new AppError('Selected preferred language folder does not exist', 400, ErrorCodes.SYSTEM_VALIDATION_ERROR);
    }

    // 3. Validate referral code (MANDATORY)
    if (!referralCode) {
      throw new AppError('Referral code is mandatory for registration', 400, ErrorCodes.REFERRAL_INVALID);
    }
    
    let referrerId = null;
    const referrer = await referralService.validateReferralCode(referralCode);
    if (!referrer) {
      throw new AppError('Invalid referral code', 400, ErrorCodes.REFERRAL_INVALID);
    }
    referrerId = referrer.id;

    // 3. Generate a unique referral code for the new user
    let uniqueReferralCode;
    let codeExists = true;
    while (codeExists) {
      uniqueReferralCode = generateCode(8);
      const checkedUser = await prisma.user.findUnique({
        where: { referralCode: uniqueReferralCode },
      });
      if (!checkedUser) {
        codeExists = false;
      }
    }

    // Generate permanent referral link and QR code base64
    const referralUrl = generateLink(uniqueReferralCode);
    const qrCode = await generateQR(referralUrl);

    // 4. Hash password
    const hashedPassword = await hashPassword(password);

    // Fetch system settings to check if admin approval is required
    const settings = await referralService.getSystemSettings();
    const requireApproval = settings.require_admin_approval === 'true';
    const isApproved = !requireApproval;

    // 5. Create user and profile
    const user = await authRepository.createUser({
      email,
      password: hashedPassword,
      referralCode: uniqueReferralCode,
      referralUrl,
      qrCode,
      referrerId,
      firstName,
      lastName,
      phoneNumber,
      isApproved,
      assignedLanguageId: preferredLanguageId,
    });

    // 6. Create node in hierarchy if auto-approved
    if (isApproved) {
      await hierarchyService.createNodeForUser(user.id, referrerId);
    }

    // 7. If there was a referrer, log the referral entry and calculate/process rewards
    if (referrerId) {
      await referralService.createReferralEntry(user.id, referrerId);
    }

    // 8. Create permanent user joining snapshot log & notify admins
    try {
      const joiningSnapshotService = require('./joiningSnapshot.service');
      await joiningSnapshotService.createSnapshotForUser(user.id);
    } catch (snapshotErr) {
      console.warn('[AuthService] User joining snapshot log notice:', snapshotErr.message);
    }

    // 9. Generate auth token
    const token = jwtService.sign({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    // Strip password from returned user object
    const { password: _, ...userWithoutPassword } = user;
    return { 
      user: userWithoutPassword, 
      token: user.isApproved ? token : null 
    };
  }

  /**
   * Log in an existing user
   */
  async login({ email, password }) {
    // 1. Find user by email
    const user = await authRepository.findByEmail(email);
    if (!user || user.isDeleted) {
      throw new AppError('Invalid email or password', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    if (!user.isApproved) {
      throw new AppError('Your account is pending admin approval.', 403, ErrorCodes.USER_SUSPENDED);
    }

    if (!user.isActive) {
      throw new AppError('Your account has been suspended by an administrator.', 403, ErrorCodes.USER_SUSPENDED);
    }

    // 2. Compare passwords
    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      throw new AppError('Invalid email or password', 401, ErrorCodes.AUTH_CREDENTIALS_INVALID);
    }

    // 3. Generate token
    const token = jwtService.sign({
      id: user.id,
      email: user.email,
      role: user.role,
    });

    // Strip password
    const { password: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, token };
  }

  /**
   * Request Password Reset OTP
   */
  async requestPasswordResetOtp(email) {
    const user = await authRepository.findByEmail(email);
    if (!user || user.isDeleted) {
      throw new Error('Email address not found');
    }

    // Limit to 5 attempts
    if (user.otpCount >= 5) {
      throw new Error('You have requested the OTP too many times (maximum 5 requests). Please contact support.');
    }

    // Generate random 4-digit OTP in range 0-1000
    const otpVal = Math.floor(Math.random() * 1001); // Range 0-1000
    const otp = String(otpVal).padStart(4, '0'); // Padded to 4 digits

    // Set expiry to 15 minutes from now
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Update database
    await prisma.user.update({
      where: { id: user.id },
      data: {
        otpCode: otp,
        otpExpiresAt,
        otpCount: user.otpCount + 1,
      },
    });

    // Send email using nodemailer
    await sendOtpEmail(email, otp);

    return { 
      message: 'OTP sent successfully', 
      remainingAttempts: 5 - (user.otpCount + 1) 
    };
  }

  /**
   * Verify OTP
   */
  async verifyPasswordResetOtp(email, otp) {
    const user = await authRepository.findByEmail(email);
    if (!user || user.isDeleted) {
      throw new Error('Email address not found');
    }

    if (!user.otpCode || user.otpCode !== otp) {
      throw new Error('Invalid OTP');
    }

    if (user.otpExpiresAt && new Date() > user.otpExpiresAt) {
      throw new Error('OTP has expired');
    }

    return { success: true, message: 'OTP verified successfully' };
  }

  /**
   * Reset Password
   */
  async resetPassword(email, otp, newPassword) {
    const user = await authRepository.findByEmail(email);
    if (!user || user.isDeleted) {
      throw new Error('Email address not found');
    }

    if (!user.otpCode || user.otpCode !== otp) {
      throw new Error('Invalid OTP');
    }

    if (user.otpExpiresAt && new Date() > user.otpExpiresAt) {
      throw new Error('OTP has expired');
    }

    // Hash the new password
    const hashedPassword = await hashPassword(newPassword);

    // Update user password and clear OTP/otpCount
    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        otpCode: null,
        otpExpiresAt: null,
        otpCount: 0,
      },
    });

    return { success: true, message: 'Password reset successful' };
  }

  /**
   * Change Password for authenticated user
   */
  async changePassword(userId, { currentPassword, newPassword }) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || user.isDeleted) {
      throw new Error('User not found');
    }

    const isMatch = await comparePassword(currentPassword, user.password);
    if (!isMatch) {
      throw new Error('Current password is incorrect');
    }

    if (currentPassword === newPassword) {
      throw new Error('New password cannot be the same as current password');
    }

    const hashedPassword = await hashPassword(newPassword);

    await prisma.user.update({
      where: { id: userId },
      data: {
        password: hashedPassword,
      },
    });

    return { success: true, message: 'Password changed successfully' };
  }

  /**
   * Purge a previously soft-deleted user and associated child records
   */
  async purgeDeletedUser(userId) {
    try {
      const targetUser = await prisma.user.findUnique({ where: { id: userId }, select: { email: true } });
      const targetEmail = targetUser?.email || '';

      await prisma.$transaction([
        prisma.userVideoProgress.deleteMany({ where: { userId } }),
        prisma.snapshotVideo.deleteMany({ where: { snapshot: { userId } } }),
        prisma.userVideoSnapshot.deleteMany({ where: { userId } }),
        prisma.userJoiningSnapshot.deleteMany({ where: { userId } }),
        prisma.languageChangeRequest.deleteMany({ where: { userId } }),
        prisma.playbackSession.deleteMany({ where: { userId } }),
        prisma.notification.deleteMany({
          where: {
            OR: [
              { userId },
              ...(targetEmail ? [{ message: { contains: targetEmail } }] : [])
            ]
          }
        }),
        prisma.referral.deleteMany({ where: { OR: [{ refereeId: userId }, { referrerId: userId }] } }),
        prisma.hierarchyNode.deleteMany({ where: { userId } }),
        prisma.profile.deleteMany({ where: { userId } }),
        prisma.user.delete({ where: { id: userId } }),
      ]);
    } catch (e) {
      console.error('[AuthService] Error purging deleted user:', e);
      try {
        await prisma.user.delete({ where: { id: userId } });
      } catch (_) {}
    }
  }
}

module.exports = new AuthService();
