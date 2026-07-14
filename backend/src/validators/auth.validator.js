const { z } = require('zod');

const registerSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  firstName: z.string().min(1, 'First name is required').optional(),
  lastName: z.string().min(1, 'Last name is required').optional(),
  phoneNumber: z.string().optional(),
  referralCode: z.string().length(8, 'Referral code must be exactly 8 characters'),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(1, 'Password is required'),
});

const requestOtpSchema = z.object({
  email: z.string().email('Invalid email address format'),
});

const verifyOtpSchema = z.object({
  email: z.string().email('Invalid email address format'),
  otp: z.string().length(4, 'OTP must be exactly 4 digits'),
});

const resetPasswordSchema = z.object({
  email: z.string().email('Invalid email address format'),
  otp: z.string().length(4, 'OTP must be exactly 4 digits'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

module.exports = {
  registerSchema,
  loginSchema,
  requestOtpSchema,
  verifyOtpSchema,
  resetPasswordSchema,
};
