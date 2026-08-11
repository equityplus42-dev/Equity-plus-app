const app = require('./app');
const env = require('./config/env');
const logger = require('./utils/logger');
const prisma = require('./config/database');

async function connectWithRetry(retries = 5, delayMs = 2000) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      await prisma.$connect();
      logger.info('Database connection established successfully.');
      return;
    } catch (error) {
      logger.warn(`Database connection attempt ${attempt}/${retries} failed: ${error.message}`);
      if (attempt < retries) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      } else {
        logger.error('Could not connect to database after maximum retries.');
      }
    }
  }
}

async function startServer() {
  try {
    // Start listening immediately on 0.0.0.0 so HTTP server is online on port 5000
    const server = app.listen(env.PORT, '0.0.0.0', () => {
      logger.info(`Server is running in ${env.NODE_ENV} mode on port ${env.PORT}`);
    });

    // Allow unlimited time for large video file uploads (no request timeout)
    server.timeout = 0;
    server.keepAliveTimeout = 0;
    server.headersTimeout = 0;

    // Connect to TiDB Cloud database asynchronously with retry
    await connectWithRetry();
  } catch (error) {
    logger.error('Failed to start server:', error);
  }
}

startServer();
