/**
 * Standard API Response Wrapper
 */
class ApiResponse {
  static success(res, message = 'Success', data = {}, statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  static error(res, message = 'An error occurred', statusCode = 500, errorCode = null, errors = null) {
    const response = {
      success: false,
      message,
    };
    if (errorCode) {
      response.errorCode = errorCode;
    }
    if (errors) {
      response.errors = errors;
    }
    return res.status(statusCode).json(response);
  }
}

module.exports = ApiResponse;
