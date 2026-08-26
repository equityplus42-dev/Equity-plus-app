const assert = require('assert');
const prisma = require('../src/config/database');
const referralService = require('../src/services/referral.service');
const hierarchyService = require('../src/services/hierarchy.service');
const userRepository = require('../src/repositories/user.repository');
const { hashPassword } = require('../src/utils/encryption');

async function runReferralClawbackAndTestUserTest() {
  console.log('🧪 Starting Referral Clawback & Test User Exclusion Tests...');

  try {
    const passwordHash = await hashPassword('TestUser@123');

    // 1. Create Referrer User (User R)
    const referrer = await prisma.user.create({
      data: {
        email: `referrer_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `REFR_${Date.now()}`,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'Referrer', lastName: 'R' } }
      }
    });
    await hierarchyService.createNodeForUser(referrer.id, null);

    // 2. TEST RULE 1: Test User (isTestUser: true) Signup Points Exclusion
    const testUser = await prisma.user.create({
      data: {
        email: `testuser_rule1_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `TU_${Date.now()}`,
        referrerId: referrer.id,
        isApproved: true,
        isTestUser: true,
        points: 0,
        profile: { create: { firstName: 'Test', lastName: 'User' } }
      }
    });
    await hierarchyService.createNodeForUser(testUser.id, referrer.id);

    const settings = await referralService.getSystemSettings();
    await referralService.distributePoints(testUser.id, 'Test User', settings);

    const referrerAfterTestUser = await prisma.user.findUnique({ where: { id: referrer.id } });
    console.log(`Referrer Points after Test User signup: ${referrerAfterTestUser.points} (Expected: 0)`);
    assert.strictEqual(referrerAfterTestUser.points, 0, 'Test User signup MUST NOT award points to Referrer');

    // 3. TEST RULE 2: Normal User Points Awarding & Deletion Clawback
    const realUser = await prisma.user.create({
      data: {
        email: `realuser_rule2_${Date.now()}@test.com`,
        password: passwordHash,
        role: 'USER',
        referralCode: `RU_${Date.now()}`,
        referrerId: referrer.id,
        isApproved: true,
        points: 0,
        profile: { create: { firstName: 'Real', lastName: 'User' } }
      }
    });
    await hierarchyService.createNodeForUser(realUser.id, referrer.id);

    // Distribute points for Real User (Level 1 = +100 PTS)
    await referralService.distributePoints(realUser.id, 'Real User', settings);

    const referrerAfterRealUser = await prisma.user.findUnique({ where: { id: referrer.id } });
    console.log(`Referrer Points after Real User signup: ${referrerAfterRealUser.points} (Expected: 100)`);
    assert.strictEqual(referrerAfterRealUser.points, 100, 'Real User signup MUST award +100 points to Referrer');

    // Delete Real User via userRepository.deleteUser
    await userRepository.deleteUser(realUser.id, 'ADMIN');

    const referrerAfterDeletion = await prisma.user.findUnique({ where: { id: referrer.id } });
    console.log(`Referrer Points after Real User deletion: ${referrerAfterDeletion.points} (Expected: 0)`);
    assert.strictEqual(referrerAfterDeletion.points, 0, 'Referrer points MUST be deducted back to 0 when referee is deleted');

    // Clean up test records
    await prisma.deletedUserLog.deleteMany({ where: { email: realUser.email } });
    await prisma.notification.deleteMany({ where: { userId: { in: [referrer.id, testUser.id] } } });
    await prisma.hierarchyNode.deleteMany({ where: { userId: { in: [referrer.id, testUser.id] } } });
    await prisma.profile.deleteMany({ where: { userId: { in: [referrer.id, testUser.id] } } });
    await prisma.user.deleteMany({ where: { id: { in: [referrer.id, testUser.id] } } });

    console.log('🎉 ALL REFERRAL CLAWBACK & TEST USER EXCLUSION TESTS PASSED PERFECTLY!');
  } catch (err) {
    console.error('❌ Test failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runReferralClawbackAndTestUserTest();
