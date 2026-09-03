const prisma = require('../src/config/database');

async function main() {
  try {
    const totalUsersInDb = await prisma.user.count();
    const approvedRealUsers = await prisma.user.count({
      where: { isDeleted: false, isApproved: true, role: 'USER', isTestUser: false }
    });
    const pendingUsers = await prisma.user.count({
      where: { isDeleted: false, isApproved: false }
    });
    const testUsers = await prisma.user.count({
      where: { isTestUser: true }
    });
    const admins = await prisma.user.count({
      where: { role: 'ADMIN' }
    });

    const allUserList = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true,
        isApproved: true,
        isTestUser: true,
        referralCode: true,
        createdAt: true,
        profile: {
          select: {
            firstName: true,
            lastName: true,
            phoneNumber: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    console.log('=== VRIDHI NETWORK USER SUMMARY ===');
    console.log(`Total Records in User Table: ${totalUsersInDb}`);
    console.log(`Real Approved Users: ${approvedRealUsers}`);
    console.log(`Pending Approval Users: ${pendingUsers}`);
    console.log(`Test Users (Developer/Testing): ${testUsers}`);
    console.log(`Admins: ${admins}`);
    console.log('\n--- DETAILED USER LIST ---');
    allUserList.forEach((u, i) => {
      const name = u.profile ? `${u.profile.firstName || ''} ${u.profile.lastName || ''}`.trim() : 'N/A';
      console.log(`${i+1}. [${u.role}] ${name} (${u.email}) - Code: ${u.referralCode} | Approved: ${u.isApproved} | TestUser: ${u.isTestUser}`);
    });
  } catch (err) {
    console.error('Error fetching user count:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
