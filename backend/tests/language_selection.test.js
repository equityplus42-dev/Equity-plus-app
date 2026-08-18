const prisma = require('../src/config/database');
const videoService = require('../src/services/video.service');
const assert = require('assert');

async function runLanguageSelectionTests() {
  console.log('\n════════════════════════════════════════════════════════');
  console.log('  VRIDHI — LEGACY USER LANGUAGE SELECTION EMPIRICAL TESTS');
  console.log('════════════════════════════════════════════════════════\n');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  // Ensure test languages exist
  let englishLang = await prisma.language.findFirst({ where: { code: 'en' } });
  if (!englishLang) {
    englishLang = await prisma.language.findFirst({ where: { name: 'English' } });
  }
  if (!englishLang) {
    englishLang = await prisma.language.create({
      data: { name: 'English Test', code: 'en_test', isDefault: true }
    });
  }

  let hindiLang = await prisma.language.findFirst({ where: { code: 'hi' } });
  if (!hindiLang) {
    hindiLang = await prisma.language.findFirst({ where: { name: 'Hindi' } });
  }
  if (!hindiLang) {
    hindiLang = await prisma.language.create({
      data: { name: 'Hindi Test', code: 'hi_test', isDefault: false }
    });
  }

  // Helper to create test legacy user
  async function createLegacyUser(emailSuffix) {
    const timestamp = Date.now() + '_' + Math.floor(Math.random() * 10000);
    const user = await prisma.user.create({
      data: {
        email: `legacy_${emailSuffix}_${timestamp}@example.com`,
        password: 'Password123!',
        referralCode: `REF_${timestamp}`,
        role: 'USER',
        profile: {
          create: {
            firstName: 'Legacy',
            lastName: 'User',
            assignedLanguageId: null, // NULL for legacy user
            languageSelectionRequired: true,
          }
        }
      },
      include: { profile: true }
    });
    return user;
  }

  // Helper cleanup
  async function cleanupUser(userId) {
    try {
      await prisma.user.delete({ where: { id: userId } });
    } catch (e) {
      // ignore
    }
  }

  // Scenario 1: Legacy user (assignedLanguageId = NULL, no snapshot) -> select English -> verify assignedLanguageId persisted, exactly 1 snapshot
  await test('Scenario 1: Legacy user (NULL lang, no snapshot) -> select language -> persisted & 1 snapshot created', async () => {
    const user = await createLegacyUser('sc1');
    try {
      // Verify initial state
      assert.strictEqual(user.profile.assignedLanguageId, null);
      const initSnapshot = await prisma.userVideoSnapshot.findUnique({ where: { userId: user.id } });
      assert.strictEqual(initSnapshot, null);

      // Select English
      await videoService.setUserLanguage(user.id, englishLang.id);

      // Verify profile assignedLanguageId
      const updatedProfile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(updatedProfile.assignedLanguageId, englishLang.id);

      // Verify snapshot count
      const snapshots = await prisma.userVideoSnapshot.findMany({ where: { userId: user.id } });
      assert.strictEqual(snapshots.length, 1);
      assert.strictEqual(snapshots[0].languageId, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // Scenario 2: Legacy user (assignedLanguageId = NULL, existing snapshot) -> select English -> verify NO duplicate snapshot, existing SnapshotVideo records untouched
  await test('Scenario 2: Legacy user (NULL lang, existing snapshot) -> select language -> no duplicate snapshot', async () => {
    const user = await createLegacyUser('sc2');
    try {
      // Pre-create a snapshot manually for this user with English
      const snapshot = await prisma.userVideoSnapshot.create({
        data: {
          userId: user.id,
          languageId: englishLang.id,
          snapshotVideoCount: 0,
          snapshotTotalDurationSeconds: 0,
          refundThresholdPercentage: 25,
          refundEligible: true,
        }
      });

      // Execute setUserLanguage
      await videoService.setUserLanguage(user.id, englishLang.id);

      // Verify snapshot count is still exactly 1
      const snapshots = await prisma.userVideoSnapshot.findMany({
        where: { userId: user.id },
        include: { snapshotVideos: true }
      });
      assert.strictEqual(snapshots.length, 1);
      assert.strictEqual(snapshots[0].id, snapshot.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // Scenario 3: Already assigned user -> POST /select-language with different lang -> HTTP 409, DB remains original lang
  await test('Scenario 3: Already assigned user -> select-language -> HTTP 409, DB unchanged', async () => {
    const user = await createLegacyUser('sc3');
    try {
      // First assign English
      await videoService.setUserLanguage(user.id, englishLang.id);

      // Try assigning Hindi
      let errorThrown = null;
      try {
        await videoService.setUserLanguage(user.id, hindiLang.id);
      } catch (err) {
        errorThrown = err;
      }

      assert.notStrictEqual(errorThrown, null, 'Should have thrown error when changing assigned language');
      assert.strictEqual(errorThrown.statusCode, 409);

      // Verify database still has English
      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // Scenario 4: Invalid language -> request rejected, no DB mutation, no snapshot
  await test('Scenario 4: Invalid language ID -> request rejected, no DB mutation', async () => {
    const user = await createLegacyUser('sc4');
    try {
      let errorThrown = null;
      try {
        await videoService.setUserLanguage(user.id, 'invalid-uuid-99999');
      } catch (err) {
        errorThrown = err;
      }

      assert.notStrictEqual(errorThrown, null, 'Should reject invalid language ID');

      // Verify DB unchanged
      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, null);

      const snapshots = await prisma.userVideoSnapshot.findMany({ where: { userId: user.id } });
      assert.strictEqual(snapshots.length, 0);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // Scenario 5: Two simultaneous requests -> Request A (English), Request B (Hindi) -> only one language persisted, only 1 snapshot, no duplicate SnapshotVideo
  await test('Scenario 5: Simultaneous requests (A & B) -> only 1 language persisted, 1 snapshot', async () => {
    const user = await createLegacyUser('sc5');
    try {
      await Promise.allSettled([
        videoService.setUserLanguage(user.id, englishLang.id),
        videoService.setUserLanguage(user.id, hindiLang.id),
      ]);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.notStrictEqual(profile.assignedLanguageId, null);
      assert.ok([englishLang.id, hindiLang.id].includes(profile.assignedLanguageId));

      const snapshots = await prisma.userVideoSnapshot.findMany({
        where: { userId: user.id },
        include: { snapshotVideos: true }
      });
      assert.strictEqual(snapshots.length, 1);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // Scenario 6: Video Hub (getUserVideos) -> NULL language receives needsLanguageSelection=true, assigned language receives needsLanguageSelection=false
  await test('Scenario 6: Video Hub getUserVideos flags needsLanguageSelection correctly', async () => {
    const user = await createLegacyUser('sc6');
    try {
      // Initial GET user videos (NULL language)
      const res1 = await videoService.getUserVideos(user.id);
      assert.strictEqual(res1.needsLanguageSelection, true);
      assert.ok(Array.isArray(res1.availableLanguages));
      assert.ok(res1.availableLanguages.length > 0);

      // Now set language
      await videoService.setUserLanguage(user.id, englishLang.id);

      // GET user videos after setting language
      const res2 = await videoService.getUserVideos(user.id);
      assert.strictEqual(res2.needsLanguageSelection, false);
      assert.strictEqual(res2.assignedLanguage.id, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  console.log('\n════════════════════════════════════════════════════════');
  console.log(`  Test Results: ${passed} Passed, ${failed} Failed`);
  console.log('════════════════════════════════════════════════════════\n');

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runLanguageSelectionTests().then(() => process.exit(0)).catch(err => {
    console.error('Test execution error:', err);
    process.exit(1);
  });
}

module.exports = runLanguageSelectionTests;
