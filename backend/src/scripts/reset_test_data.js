const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function resetTestData() {
  console.log('--- Starting Reset for Test User Notification & Transaction History ---');

  // Find all test users (email or profile containing "test")
  const testUsers = await prisma.user.findMany({
    where: {
      OR: [
        { email: { contains: 'test' } },
        { profile: { firstName: { contains: 'test' } } },
        { profile: { lastName: { contains: 'test' } } }
      ]
    },
    select: {
      id: true,
      email: true,
      profile: { select: { firstName: true, lastName: true } }
    }
  });

  console.log(`Found ${testUsers.length} test user(s):`, testUsers);
  const testUserIds = testUsers.map((u) => u.id);

  if (testUserIds.length === 0) {
    console.log('No test user found.');
    return;
  }

  // 1. Delete Refund Requests for test users
  const deletedRefunds = await prisma.refundRequest.deleteMany({
    where: {
      userId: { in: testUserIds }
    }
  });
  console.log(`Deleted ${deletedRefunds.count} refund request(s) for test users.`);

  // 2. Delete Product Accesses for test users
  const deletedAccesses = await prisma.userProductAccess.deleteMany({
    where: {
      userId: { in: testUserIds }
    }
  });
  console.log(`Deleted ${deletedAccesses.count} product access record(s) for test users.`);

  // 3. Delete Payments / Transactions for test users
  const deletedPayments = await prisma.payment.deleteMany({
    where: {
      userId: { in: testUserIds }
    }
  });
  console.log(`Deleted ${deletedPayments.count} payment/transaction record(s) for test users.`);

  // 4. Delete Notifications for test users
  const deletedUserNotifications = await prisma.notification.deleteMany({
    where: {
      userId: { in: testUserIds }
    }
  });
  console.log(`Deleted ${deletedUserNotifications.count} notification(s) assigned to test users.`);

  // 5. Delete Admin notifications referring to test users or test payments/signups
  const adminTestNotifications = await prisma.notification.deleteMany({
    where: {
      OR: [
        { message: { contains: 'test@gmail.com' } },
        { message: { contains: 'test test' } },
        { title: { contains: 'test' } }
      ]
    }
  });
  console.log(`Deleted ${adminTestNotifications.count} admin notification(s) referencing test user.`);

  // 6. Reset test user points balance to 0
  await prisma.user.updateMany({
    where: { id: { in: testUserIds } },
    data: { points: 0 }
  });
  console.log('Reset test user reward points to 0.');

  console.log('--- Test User Notification & Transaction History Successfully Reset! ---');
}

module.exports = resetTestData;

if (require.main === module) {
  resetTestData()
    .catch((err) => console.error('Error resetting test data:', err))
    .finally(() => prisma.$disconnect());
}
