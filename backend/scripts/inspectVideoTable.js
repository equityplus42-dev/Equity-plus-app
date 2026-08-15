require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function inspect() {
  try {
    const cols = await prisma.$queryRaw`DESCRIBE Video`;
    console.log('Live Video table columns:');
    console.log(JSON.stringify(cols, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    await prisma.$disconnect();
  }
}
inspect();
