const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // 1. Seed Admin User (password is 'Admin123!' hashed with bcrypt)
  const adminEmail = 'admin@referral.com';
  const adminPasswordHash = '$2b$10$P5i/U8u/wA1Bf5m0eU7mHe2pWnE75P4m3aGv8.U2q163c4.1H0.yS';

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000000',
      email: adminEmail,
      password: adminPasswordHash,
      role: 'ADMIN',
      referralCode: 'ADMINREF',
      isApproved: true,
      profile: {
        create: {
          firstName: 'System',
          lastName: 'Administrator',
          phoneNumber: '+1234567890',
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150',
          bio: 'Primary Administrator for the Hierarchical Referral System.',
        }
      }
    }
  });

  console.log(`Admin user created/verified: ${admin.email}`);

  // 2. Seed Default System Settings
  const defaultSettings = [
    { key: 'points_level_1', value: '100', description: 'Points awarded to the direct referrer (Level 1)' },
    { key: 'points_level_2', value: '50', description: 'Points awarded to the level 2 indirect referrer' },
    { key: 'points_level_3', value: '25', description: 'Points awarded to the level 3 indirect referrer' },
    { key: 'max_hierarchy_depth', value: '3', description: 'Maximum depth level for awarding referral rewards' },
    { key: 'require_admin_approval', value: 'false', description: 'If true, new referrals must be manually approved by admin before points are paid out' }
  ];

  for (const setting of defaultSettings) {
    await prisma.systemSettings.upsert({
      where: { key: setting.key },
      update: {},
      create: {
        key: setting.key,
        value: setting.value,
        description: setting.description
      }
    });
  }

  console.log('Default settings seeded successfully.');
  console.log('Seeding completed.');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
