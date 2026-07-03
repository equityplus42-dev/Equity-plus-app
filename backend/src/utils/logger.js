const pino = require('pino');
const env = require('../config/env');

const isDevelopment = env.NODE_ENV === 'development';

const pinoInstance = pino({
  level: env.LOG_LEVEL || (isDevelopment ? 'debug' : 'info'),
  transport: isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
});

/**
 * Format arguments into a standard structured log object
 */
function formatArgs(msg, ...args) {
  if (args.length === 0) return { msg };
  if (args.length === 1 && typeof args[0] === 'object') {
    return { payload: args[0], msg };
  }
  return { payload: args, msg };
}

module.exports = {
  info: (msg, ...args) => {
    const formatted = formatArgs(msg, ...args);
    if (formatted.payload) {
      pinoInstance.info(formatted.payload, formatted.msg);
    } else {
      pinoInstance.info(formatted.msg);
    }
  },
  warn: (msg, ...args) => {
    const formatted = formatArgs(msg, ...args);
    if (formatted.payload) {
      pinoInstance.warn(formatted.payload, formatted.msg);
    } else {
      pinoInstance.warn(formatted.msg);
    }
  },
  error: (msg, ...args) => {
    const formatted = formatArgs(msg, ...args);
    if (args[0] instanceof Error) {
      pinoInstance.error(args[0], msg);
    } else if (formatted.payload) {
      pinoInstance.error(formatted.payload, formatted.msg);
    } else {
      pinoInstance.error(formatted.msg);
    }
  },
  debug: (msg, ...args) => {
    const formatted = formatArgs(msg, ...args);
    if (formatted.payload) {
      pinoInstance.debug(formatted.payload, formatted.msg);
    } else {
      pinoInstance.debug(formatted.msg);
    }
  },
  logger: pinoInstance,
};
