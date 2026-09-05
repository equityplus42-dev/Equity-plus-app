const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Cleaning up admin/developer joining notifications...');

  const result = await prisma.notification.deleteMany({
    where: {
      type: 'USER_JOINED',
      OR: [
        { message: { contains: 'admin@equityplus.com' } },
        { message: { contains: 'developer@vridhi.com' } },
        { message: { contains: 'Super Admin' } },
        { message: { contains: 'System Developer' } },
        { message: { contains: 'test@gmail.com' } },
      ],
    },
  });

  console.log(`Successfully deleted ${result.count} non-user joining notifications from database.`);
}

main()
  .catch((e) => {
    console.error('Error deleting notifications:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
