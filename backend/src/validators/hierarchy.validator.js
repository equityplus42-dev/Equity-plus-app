const { z } = require('zod');

const getHierarchySchema = z.object({
  depth: z.string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : undefined))
    .refine((val) => val === undefined || (val > 0 && val <= 10), {
      message: 'Depth must be a number between 1 and 10',
    }),
});

module.exports = {
  getHierarchySchema,
};
