const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const users = await prisma.user.findMany({
    select: {
      id: true,
      email: true,
      role: true,
      profile: {
        select: {
          firstName: true,
          lastName: true,
          phoneNumber: true
        }
      }
    }
  });
  console.log('USERS:', JSON.stringify(users, null, 2));

  const notifications = await prisma.notification.findMany();
  console.log('NOTIFICATIONS COUNT:', notifications.length);
  console.log('NOTIFICATIONS:', JSON.stringify(notifications, null, 2));

  const payments = await prisma.payment.findMany();
  console.log('PAYMENTS COUNT:', payments.length);
  console.log('PAYMENTS:', JSON.stringify(payments, null, 2));

  const productAccesses = await prisma.userProductAccess.findMany();
  console.log('PRODUCT ACCESSES COUNT:', productAccesses.length);
  console.log('PRODUCT ACCESSES:', JSON.stringify(productAccesses, null, 2));

  const refundRequests = await prisma.refundRequest.findMany();
  console.log('REFUND REQUESTS COUNT:', refundRequests.length);
  console.log('REFUND REQUESTS:', JSON.stringify(refundRequests, null, 2));

  const videoProgress = await prisma.userVideoProgress.findMany();
  console.log('VIDEO PROGRESS COUNT:', videoProgress.length);

  const videoSnapshots = await prisma.userVideoSnapshot.findMany();
  console.log('VIDEO SNAPSHOTS COUNT:', videoSnapshots.length);
}

run()
  .catch((err) => console.error(err))
  .finally(() => prisma.$disconnect());
