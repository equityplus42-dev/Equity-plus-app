const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- PURGING NOTIFICATIONS FOR DELETED / PURGED USERS ---');

  const activeUsers = await prisma.user.findMany({
    where: { isDeleted: false },
    select: { email: true, id: true }
  });

  const activeEmails = new Set(activeUsers.map(u => u.email.toLowerCase()));

  const allNotifications = await prisma.notification.findMany({
    where: { type: 'USER_JOINED' }
  });

  let deletedCount = 0;

  for (const n of allNotifications) {
    // Extract email from message, e.g., 'New User Registered: "Name" (email@domain.com) joined...'
    const match = n.message.match(/\(([^)]+)\)/);
    if (match && match[1]) {
      const emailInMsg = match[1].trim().toLowerCase();
      if (!activeEmails.has(emailInMsg)) {
        await prisma.notification.delete({ where: { id: n.id } });
        console.log(`Deleted orphaned joining notification for deleted email: "${emailInMsg}"`);
        deletedCount++;
      }
    }
  }

  console.log(`Done! Purged ${deletedCount} orphaned notifications for deleted users.`);
}

main()
  .catch((e) => {
    console.error('Error cleaning deleted user notifications:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
