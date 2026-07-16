const pino = require('pino');
const env = require('../config/env');

const isDevelopment = env.NODE_ENV === 'development';

// In production (e.g. Vercel serverless), use plain JSON output — no pino-pretty.
// pino-pretty transport uses worker_threads which are not available in serverless.
let pinoInstance;
if (isDevelopment) {
  try {
    const pretty = require('pino-pretty');
    pinoInstance = pino(
      { level: env.LOG_LEVEL || 'debug' },
      pretty({ colorize: true, translateTime: 'SYS:standard', ignore: 'pid,hostname' })
    );
  } catch (_) {
    pinoInstance = pino({ level: env.LOG_LEVEL || 'debug' });
  }
} else {
  pinoInstance = pino({ level: env.LOG_LEVEL || 'info' });
}

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
