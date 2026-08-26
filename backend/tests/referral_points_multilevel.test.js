const assert = require('assert');
const prisma = require('../src/config/database');
const referralService = require('../src/services/referral.service');
const hierarchyService = require('../src/services/hierarchy.service');
const { hashPassword } = require('../src/utils/encryption');

async function runMultiLevelReferralPointsTest() {
  console.log('🧪 Starting Multi-Level Referral Points System Test...');

  try {
    const passwordHash = await hashPassword('TestUser@123');

    // 1. Create Level 0 Root Referrer User (User A)
    const userA = await prisma.user.create({
      data: {
        email: `usera_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `REFA_${Date.now()}`,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'User', lastName: 'A' } }
      }
    });
    await hierarchyService.createNodeForUser(userA.id, null);

    // 2. Create Level 1 Referrer User (User B) referred by User A
    const userB = await prisma.user.create({
      data: {
        email: `userb_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `REFB_${Date.now()}`,
        referrerId: userA.id,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'User', lastName: 'B' } }
      }
    });
    await hierarchyService.createNodeForUser(userB.id, userA.id);

    // 3. Create Level 2 Referrer User (User C) referred by User B
    const userC = await prisma.user.create({
      data: {
        email: `userc_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `REFC_${Date.now()}`,
        referrerId: userB.id,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'User', lastName: 'C' } }
      }
    });
    await hierarchyService.createNodeForUser(userC.id, userB.id);

    // 4. Create Level 3 Referee User (User D) referred by User C
    const userD = await prisma.user.create({
      data: {
        email: `userd_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `REFD_${Date.now()}`,
        referrerId: userC.id,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'User', lastName: 'D' } }
      }
    });
    await hierarchyService.createNodeForUser(userD.id, userC.id);

    console.log('✓ Multi-level user tree created: UserA -> UserB -> UserC -> UserD');

    // 5. Execute Multi-Level Points Distribution for User D signup
    const settings = await referralService.getSystemSettings();
    await referralService.distributePoints(userD.id, 'User D', settings);

    // 6. Fetch updated point balances from database
    const [updatedA, updatedB, updatedC, updatedD] = await Promise.all([
      prisma.user.findUnique({ where: { id: userA.id } }),
      prisma.user.findUnique({ where: { id: userB.id } }),
      prisma.user.findUnique({ where: { id: userC.id } }),
      prisma.user.findUnique({ where: { id: userD.id } })
    ]);

    console.log(`Updated Points -> User C (Level 1 Direct): ${updatedC.points} PTS (Expected: 100)`);
    console.log(`Updated Points -> User B (Level 2 Indirect): ${updatedB.points} PTS (Expected: 50)`);
    console.log(`Updated Points -> User A (Level 3 Indirect): ${updatedA.points} PTS (Expected: 25)`);

    assert.strictEqual(updatedC.points, 100, 'Direct Referrer (User C) must earn 100 points');
    assert.strictEqual(updatedB.points, 50, 'Level 2 Indirect Referrer (User B) must earn 50 points');
    assert.strictEqual(updatedA.points, 25, 'Level 3 Indirect Referrer (User A) must earn 25 points');
    assert.strictEqual(updatedD.points, 0, 'New Referee (User D) initial points should be 0');

    // Clean up test users from DB
    const testIds = [userA.id, userB.id, userC.id, userD.id];
    await prisma.notification.deleteMany({ where: { userId: { in: testIds } } });
    await prisma.hierarchyNode.deleteMany({ where: { userId: { in: testIds } } });
    await prisma.profile.deleteMany({ where: { userId: { in: testIds } } });
    await prisma.user.deleteMany({ where: { id: { in: testIds } } });

    console.log('🎉 ALL MULTI-LEVEL REFERRAL POINTS TESTS PASSED PERFECTLY!');
  } catch (err) {
    console.error('❌ Referral points test failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runMultiLevelReferralPointsTest();
