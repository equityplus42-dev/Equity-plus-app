const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  try {
    const adminEmail = 'admin@equilty.com';
    const rawPassword = 'AdminPassword123!';
    
    // Check if an admin exists
    const existingAdmin = await prisma.user.findFirst({
      where: { role: 'ADMIN' },
    });

    if (existingAdmin) {
      console.log('An admin already exists!');
      console.log('Email:', existingAdmin.email);
      // We don't print the password because it's hashed, but we can reset it if needed.
      // Let's just update the password for the existing admin to ensure the user can log in.
      const hashedPassword = await bcrypt.hash(rawPassword, 10);
      await prisma.user.update({
        where: { id: existingAdmin.id },
        data: { password: hashedPassword }
      });
      console.log('Password has been reset for this admin account.');
      console.log('Email:', existingAdmin.email);
      console.log('Password:', rawPassword);
      return;
    }

    console.log('No admin found. Creating a new admin account...');
    
    // Hash password
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    // Create user and profile
    const newAdmin = await prisma.user.create({
      data: {
        email: adminEmail,
        password: hashedPassword,
        role: 'ADMIN',
        referralCode: 'ADMIN-MASTER-CODE', // Unique code
        isApproved: true,
        profile: {
          create: {
            firstName: 'Super',
            lastName: 'Admin',
          }
        }
      },
    });

    console.log('Admin account created successfully!');
    console.log('Email:', adminEmail);
    console.log('Password:', rawPassword);

  } catch (error) {
    console.error('Error creating admin:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
