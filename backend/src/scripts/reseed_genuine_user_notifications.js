const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const notificationService = require('../services/notification.service');

async function main() {
  console.log('--- FETCHING ALL REGISTERED USERS FROM DB ---');
  const allUsers = await prisma.user.findMany({
    where: { isDeleted: false },
    include: {
      profile: true,
      referrer: { include: { profile: true } },
    },
    orderBy: { createdAt: 'asc' },
  });

  console.log(`Total users found: ${allUsers.length}`);

  const genuineUsers = allUsers.filter(
    (u) => u.role === 'USER' && !u.isTestUser && u.email !== 'test@gmail.com'
  );

  console.log(`Genuine regular users found: ${genuineUsers.length}`);

  let createdCount = 0;

  for (const user of genuineUsers) {
    const userName = user.profile
      ? `${user.profile.firstName || ''} ${user.profile.lastName || ''}`.trim() || user.email
      : user.email;

    const referrerName = user.referrer?.profile
      ? `${user.referrer.profile.firstName || ''} ${user.referrer.profile.lastName || ''}`.trim() || user.referrer.email
      : user.referrer?.email || null;

    const joinMsg = `New User Registered: "${userName}" (${user.email}) joined on ${new Date(user.createdAt).toLocaleDateString()} using referral code ${user.referralCode || 'N/A'}${referrerName ? ` (Referred by ${referrerName})` : ''}.`;

    // Check if notification already exists to avoid duplicates
    const existing = await prisma.notification.findFirst({
      where: {
        type: 'USER_JOINED',
        message: { contains: user.email },
      },
    });

    if (!existing) {
      const admins = await prisma.user.findMany({
        where: { role: { in: ['ADMIN', 'DEVELOPER'] }, isDeleted: false },
        select: { id: true },
      });

      for (const admin of admins) {
        await prisma.notification.create({
          data: {
            userId: admin.id,
            title: 'New User Joined! 👤',
            message: joinMsg,
            type: 'USER_JOINED',
            createdAt: user.createdAt,
          },
        });
      }
      console.log(`Created joining notification for user: "${userName}" (${user.email})`);
      createdCount++;
    } else {
      console.log(`Joining notification already exists for: "${userName}" (${user.email})`);
    }
  }

  console.log(`Done! Reseeded ${createdCount} genuine user joining notifications.`);
}

main()
  .catch((e) => {
    console.error('Error reseeding notifications:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
