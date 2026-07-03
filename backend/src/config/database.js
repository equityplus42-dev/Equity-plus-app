const { PrismaClient } = require('@prisma/client');
const env = require('./env');

// Initialize Prisma client with log levels driven by environment helper
const prisma = new PrismaClient({
  log: env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

module.exports = prisma;
