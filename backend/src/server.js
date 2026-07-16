const app = require('./app');
const env = require('./config/env');
const logger = require('./utils/logger');
const prisma = require('./config/database');

async function startServer() {
  try {
    // Test database connection
    await prisma.$connect();
    logger.info('Database connection established successfully.');

    // Start listening (explicitly bind to 0.0.0.0 to allow physical devices on the local network to connect)
    app.listen(env.PORT, '0.0.0.0', () => {
      logger.info(`Server is running in ${env.NODE_ENV} mode on port ${env.PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
