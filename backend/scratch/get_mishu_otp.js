const prisma = require('../src/config/database');

async function main() {
  try {
    const mishu = await prisma.user.findFirst({
      where: {
        OR: [
          { email: { contains: 'mishu' } },
          {
            profile: {
              firstName: { contains: 'Mishu' }
            }
          }
        ]
      },
      include: { profile: true }
    });

    if (!mishu) {
      console.log('No user found matching Mishu.');
      return;
    }

    console.log('=== MISHU USER RECORD ===');
    console.log(`Name: ${mishu.profile?.firstName} ${mishu.profile?.lastName}`);
    console.log(`Email: ${mishu.email}`);
    console.log(`Phone: ${mishu.profile?.phoneNumber}`);
    console.log(`Active OTP Code: ${mishu.otpCode || 'No active OTP code'}`);
    console.log(`OTP Expiration: ${mishu.otpExpiresAt || 'N/A'}`);
    console.log(`OTP Attempt Count: ${mishu.otpCount}`);
  } catch (err) {
    console.error('Error fetching Mishu OTP:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
