const app = require('./app');
const env = require('./config/env');
const logger = require('./utils/logger');
const prisma = require('./config/database');

async function startServer() {
  try {
    // Test database connection
    await prisma.$connect();
    logger.info('Database connection established successfully.');

    // Start listening
    app.listen(env.PORT, () => {
      logger.info(`Server is running in ${env.NODE_ENV} mode on port ${env.PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
