const prisma = require('../src/config/database');
const bcrypt = require('bcrypt');

async function main() {
  const email = 'saswatikundukolkata@gmail.com';
  const newPassword = 'Asdfg@1357';

  try {
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      console.error(`User with email ${email} not found.`);
      return;
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword }
    });

    console.log('=== PASSWORD RESET SUCCESSFUL ===');
    console.log(`User Name: Saswati Kundu`);
    console.log(`Email: ${email}`);
    console.log(`New Password: ${newPassword}`);
  } catch (err) {
    console.error('Error resetting password:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
