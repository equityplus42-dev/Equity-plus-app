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

class AuthService {
  /**
   * Register a new user
   */
  async register({ email, password, referralCode, firstName, lastName, phoneNumber }) {
    // 1. Check if user already exists
    const existingUser = await authRepository.findByEmail(email);
    if (existingUser) {
      throw new Error('Email is already registered');
    }

    // 2. Validate referral code (MANDATORY)
    if (!referralCode) {
      throw new Error('Referral code is mandatory for registration');
    }
    
    let referrerId = null;
    const referrer = await referralService.validateReferralCode(referralCode);
    if (!referrer) {
      throw new Error('Invalid referral code');
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
    });

    // 6. Create node in hierarchy if auto-approved
    if (isApproved) {
      await hierarchyService.createNodeForUser(user.id, referrerId);
    }

    // 7. If there was a referrer, log the referral entry and calculate/process rewards
    if (referrerId) {
      await referralService.createReferralEntry(user.id, referrerId);
    }

    // 8. Generate auth token
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
      throw new Error('Invalid email or password');
    }

    if (!user.isApproved) {
      throw new Error('Your account is pending admin approval.');
    }

    if (!user.isActive) {
      throw new Error('Your account has been suspended by an administrator.');
    }

    // 2. Compare passwords
    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      throw new Error('Invalid email or password');
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
}

module.exports = new AuthService();
