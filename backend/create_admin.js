const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  try {
    const adminEmail = 'admin@vridhinetwork.com';
    const rawPassword = 'AdminPassword123';
    
    // Check if an admin exists
    const existingAdmin = await prisma.user.findFirst({
      where: { role: 'ADMIN' },
    });

    if (existingAdmin) {
      console.log(`Admin account already exists (${existingAdmin.email}). Existing password preserved.`);
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
