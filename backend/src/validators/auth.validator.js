const { z } = require('zod');

const registerSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  firstName: z.string().min(1, 'First name is required').optional(),
  lastName: z.string().min(1, 'Last name is required').optional(),
  phoneNumber: z.string().optional(),
  referralCode: z.string().length(8, 'Referral code must be exactly 8 characters').optional().or(z.literal('')),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(1, 'Password is required'),
});

module.exports = {
  registerSchema,
  loginSchema,
};
