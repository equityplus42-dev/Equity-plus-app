const ErrorCodes = {
  // Authentication Errors
  AUTH_CREDENTIALS_INVALID: 'AUTH_001',
  AUTH_UNAUTHORIZED: 'AUTH_002',
  AUTH_TOKEN_EXPIRED: 'AUTH_003',
  AUTH_RATE_LIMIT: 'AUTH_004',
  
  // User Errors
  USER_NOT_FOUND: 'USER_001',
  USER_EMAIL_EXISTS: 'USER_002',
  USER_SUSPENDED: 'USER_003',
  
  // Referral Errors
  REFERRAL_INVALID: 'REFERRAL_001',
  REFERRAL_ALREADY_EXISTS: 'REFERRAL_002',
  
  // Hierarchy Errors
  HIERARCHY_CIRCULAR: 'HIERARCHY_001',
  HIERARCHY_NODE_MISSING: 'HIERARCHY_002',
  
  // System Errors
  SYSTEM_DATABASE_ERROR: 'SYS_001',
  SYSTEM_VALIDATION_ERROR: 'VALIDATION_001',
  SYSTEM_NOT_FOUND: 'SYS_002'
};

class AppError extends Error {
  constructor(message, statusCode, errorCode) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = {
  AppError,
  ErrorCodes
};
