const { PrismaClient } = require('@prisma/client');
const generateCode = require('./src/services/referral/generateCode');
const generateLink = require('./src/services/referral/generateLink');
const { generateQR } = require('./src/services/qr.service');

const prisma = new PrismaClient();

async function updateAdminReferral() {
  try {
    const admin = await prisma.user.findFirst({
      where: { role: 'ADMIN' },
    });

    if (!admin) {
      console.log('No admin found!');
      return;
    }

    // Generate a new 8 char alphanumeric code
    const newCode = generateCode(8);
    const referralUrl = generateLink(newCode);
    const qrCode = await generateQR(referralUrl);

    // Update in DB
    await prisma.user.update({
      where: { id: admin.id },
      data: {
        referralCode: newCode,
        referralUrl: referralUrl,
        qrCode: qrCode
      }
    });

    console.log(`Successfully updated admin referral code to: ${newCode}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateAdminReferral();
