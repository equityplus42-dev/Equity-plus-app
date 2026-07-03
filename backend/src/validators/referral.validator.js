const { z } = require('zod');

const updateReferralStatusSchema = z.object({
  status: z.enum(['PENDING', 'APPROVED', 'REJECTED'], {
    errorMap: () => ({ message: "Status must be either 'PENDING', 'APPROVED', or 'REJECTED'" }),
  }),
});

module.exports = {
  updateReferralStatusSchema,
};
