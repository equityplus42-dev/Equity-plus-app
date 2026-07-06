const { z } = require('zod');

const updateProfileSchema = z.object({
  firstName: z.string().min(1, 'First name cannot be empty').optional(),
  lastName: z.string().min(1, 'Last name cannot be empty').optional(),
  phoneNumber: z.string().optional(),
  whatsApp: z.string().optional(),
  state: z.string().optional(),
  district: z.string().optional(),
  bio: z.string().max(500, 'Bio must be less than 500 characters').optional(),
  panNumber: z.string().optional(),
  aadharNumber: z.string().optional(),
});

module.exports = {
  updateProfileSchema,
};
