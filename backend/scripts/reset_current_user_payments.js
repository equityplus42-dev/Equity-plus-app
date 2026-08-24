const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function resetAllUserPayments() {
  console.log('🔍 Resetting payment records in database...');

  const paymentDeleteResult = await prisma.payment.deleteMany({});
  const accessDeleteResult = await prisma.userProductAccess.deleteMany({});

  console.log(`✅ Cleared ${paymentDeleteResult.count} payment record(s).`);
  console.log(`✅ Cleared ${accessDeleteResult.count} product access record(s).`);
  console.log('🎉 All users can now test the Razorpay Payment Checkout screen!');
}

resetAllUserPayments()
  .catch((err) => {
    console.error('❌ Error resetting payments:', err);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
