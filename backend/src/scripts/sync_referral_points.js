const prisma = require('../config/database');
const referralService = require('../services/referral.service');

async function syncAllUserReferralPoints() {
  console.log('🔄 Starting Database Referral Points Audit & Synchronization...');

  try {
    // 1. Fetch all non-deleted users
    const users = await prisma.user.findMany({
      where: { isDeleted: false },
    });

    console.log(`Auditing ${users.length} active database users...`);

    // Reset all user points to 0 before calculating exact valid points
    await prisma.user.updateMany({
      where: { isDeleted: false },
      data: { points: 0 },
    });

    const settings = await referralService.getSystemSettings();

    // 2. Fetch all APPROVED referrals
    const approvedReferrals = await prisma.referral.findMany({
      where: {
        status: 'APPROVED',
        referee: { isDeleted: false },
        referrer: { isDeleted: false },
      },
      include: { referee: true },
    });

    console.log(`Found ${approvedReferrals.length} approved referrals in database.`);

    // 3. Re-distribute exact points up the hierarchy chain for each approved referral
    for (const r of approvedReferrals) {
      const refereeName = r.referee.email;
      await referralService.distributePoints(r.refereeId, refereeName, settings);
    }

    // 4. Print updated user point balances
    const updatedUsers = await prisma.user.findMany({
      where: { isDeleted: false },
      select: { id: true, email: true, role: true, points: true, isTestUser: true },
    });

    console.log('\n================================================--');
    console.log('✅ UPDATED DATABASE USER REFERRAL POINTS SUMMARY:');
    console.log('================================================--');
    updatedUsers.forEach((u) => {
      console.log(`• ${u.email} (${u.role}${u.isTestUser ? ' - TEST' : ''}): ${u.points} PTS`);
    });
    console.log('================================================--\n');

    return updatedUsers;
  } catch (err) {
    console.error('❌ Error syncing referral points:', err);
    throw err;
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  syncAllUserReferralPoints();
}

module.exports = syncAllUserReferralPoints;
