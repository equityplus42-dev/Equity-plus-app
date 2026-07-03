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
    });

    // 6. Create node in hierarchy (Deferred to admin approval)
    // await hierarchyService.createNodeForUser(user.id, referrerId);

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
}

module.exports = new AuthService();
