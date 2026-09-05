const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- PURGING NOTIFICATIONS FOR DELETED / PURGED USERS ---');

  const activeUsers = await prisma.user.findMany({
    where: { isDeleted: false },
    select: { email: true, id: true }
  });

  const activeUserIds = activeUsers.map(u => u.id);
  const activeEmails = new Set(activeUsers.map(u => u.email.toLowerCase()));

  // 1. Delete notifications for inactive/deleted user IDs
  const deletedById = await prisma.notification.deleteMany({
    where: {
      userId: { notIn: activeUserIds }
    }
  });
  console.log(`Deleted ${deletedById.count} notifications for inactive/deleted admin/user IDs.`);

  // 2. Delete USER_JOINED notifications for non-existent emails
  const allJoinedNotifs = await prisma.notification.findMany({
    where: { type: 'USER_JOINED' }
  });

  let deletedCount = 0;
  for (const n of allJoinedNotifs) {
    const match = n.message.match(/\(([^)]+)\)/);
    if (match && match[1]) {
      const emailInMsg = match[1].trim().toLowerCase();
      if (!activeEmails.has(emailInMsg)) {
        await prisma.notification.deleteMany({ where: { id: n.id } });
        console.log(`Deleted orphaned joining notification for deleted email: "${emailInMsg}"`);
        deletedCount++;
      }
    }
  }

  console.log(`Done! Purged ${deletedCount} orphaned notifications for deleted user emails.`);
}

main()
  .catch((e) => {
    console.error('Error cleaning deleted user notifications:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
