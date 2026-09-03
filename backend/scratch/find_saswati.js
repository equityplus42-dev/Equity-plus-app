const prisma = require('../src/config/database');

async function main() {
  try {
    const activeUsers = await prisma.user.findMany({
      where: {
        OR: [
          { email: { contains: 'saswati' } },
          { email: { contains: 'kundu' } },
          {
            profile: {
              OR: [
                { firstName: { contains: 'saswati' } },
                { lastName: { contains: 'kundu' } },
                { firstName: { contains: 'Saswati' } },
                { lastName: { contains: 'Kundu' } },
              ]
            }
          }
        ]
      },
      include: { profile: true }
    });

    const deletedLogs = await prisma.deletedUserLog.findMany({
      where: {
        OR: [
          { email: { contains: 'saswati' } },
          { email: { contains: 'kundu' } },
          { firstName: { contains: 'saswati' } },
          { lastName: { contains: 'kundu' } },
          { firstName: { contains: 'Saswati' } },
          { lastName: { contains: 'Kundu' } },
        ]
      }
    });

    console.log('=== ACTIVE USERS MATCHING SASWATI KUNDU ===');
    console.log(JSON.stringify(activeUsers, null, 2));

    console.log('\n=== DELETED USER LOGS MATCHING SASWATI KUNDU ===');
    console.log(JSON.stringify(deletedLogs, null, 2));
  } catch (err) {
    console.error('Error finding user:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
