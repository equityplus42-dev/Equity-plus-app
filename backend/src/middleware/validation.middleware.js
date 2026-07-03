const ApiResponse = require('../utils/apiResponse');

/**
 * Zod Schema validation middleware
 * @param {import('zod').ZodSchema} schema 
 * @param {'body'|'query'|'params'} source 
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      const formattedErrors = result.error.issues.map((err) => ({
        field: err.path.join('.'),
        message: err.message,
      }));
      return ApiResponse.error(res, 'Validation error', 400, null, formattedErrors);
    }

    // Replace the request source with the parsed/validated data (handles coercion/transformations)
    req[source] = result.data;
    next();
  };
};

module.exports = validate;
