const prisma = require('../src/config/database');
const videoService = require('../src/services/video.service');
const assert = require('assert');

async function runLegacyLanguageSelectionTests() {
  console.log('\n════════════════════════════════════════════════════════');
  console.log('  VRIDHI — LEGACY USER LANGUAGE SELECTION STRICT CUTOFF TESTS');
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

  // Helper to create test user
  async function createTestUser({ emailSuffix, createdAt, assignedLanguageId = null, languageSelectionRequired = false }) {
    const timestamp = Date.now() + '_' + Math.floor(Math.random() * 10000);
    const user = await prisma.user.create({
      data: {
        email: `cutoff_${emailSuffix}_${timestamp}@example.com`,
        password: 'Password123!',
        referralCode: `REF_${timestamp}`,
        role: 'USER',
        createdAt: createdAt || new Date(),
        profile: {
          create: {
            firstName: 'Test',
            lastName: 'User',
            assignedLanguageId,
            languageSelectionRequired,
          }
        }
      },
      include: { profile: true }
    });
    return user;
  }

  // Cleanup helper
  async function cleanupUser(userId) {
    try {
      await prisma.user.delete({ where: { id: userId } });
    } catch (e) {
      // ignore
    }
  }

  const oldDate = new Date('2026-07-01T10:00:00.000Z');
  const newDate = new Date('2026-08-16T10:00:00.000Z');

  // TEST 1: Old user + no language (languageSelectionRequired = true) -> popup appears
  await test('TEST 1: Old user + no language -> needsLanguageSelection = true', async () => {
    const user = await createTestUser({
      emailSuffix: 't1',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      const res = await videoService.getUserVideos(user.id);
      assert.strictEqual(res.needsLanguageSelection, true);
      assert.ok(Array.isArray(res.availableLanguages));
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 2: Old user + existing language -> popup does NOT appear
  await test('TEST 2: Old user + existing language -> needsLanguageSelection = false', async () => {
    const user = await createTestUser({
      emailSuffix: 't2',
      createdAt: oldDate,
      assignedLanguageId: englishLang.id,
      languageSelectionRequired: false,
    });
    try {
      const res = await videoService.getUserVideos(user.id);
      assert.strictEqual(res.needsLanguageSelection, false);
      assert.strictEqual(res.assignedLanguage.id, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 3: New user + assigned language -> popup does NOT appear
  await test('TEST 3: New user + assigned language -> needsLanguageSelection = false', async () => {
    const user = await createTestUser({
      emailSuffix: 't3',
      createdAt: newDate,
      assignedLanguageId: englishLang.id,
      languageSelectionRequired: false,
    });
    try {
      const res = await videoService.getUserVideos(user.id);
      assert.strictEqual(res.needsLanguageSelection, false);
      assert.strictEqual(res.assignedLanguage.id, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 4: New user + artificially NULL language -> popup does NOT appear (CRITICAL REGRESSION TEST!)
  await test('TEST 4: New user + artificially NULL language -> needsLanguageSelection = false (NULL != legacy user)', async () => {
    const user = await createTestUser({
      emailSuffix: 't4',
      createdAt: newDate,
      assignedLanguageId: null,
      languageSelectionRequired: false, // New account has default false!
    });
    try {
      const res = await videoService.getUserVideos(user.id);
      assert.strictEqual(res.needsLanguageSelection, false, 'New user with NULL language must NEVER see legacy popup');
      assert.strictEqual(res.assignedLanguage, null);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 5: Legacy user selects language -> saved, flag false, 1 snapshot created
  await test('TEST 5: Legacy user selects language -> assigned, flag becomes false, 1 snapshot created', async () => {
    const user = await createTestUser({
      emailSuffix: 't5',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      await videoService.setUserLanguage(user.id, englishLang.id);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, englishLang.id);
      assert.strictEqual(profile.languageSelectionRequired, false);

      const snapshots = await prisma.userVideoSnapshot.findMany({ where: { userId: user.id } });
      assert.strictEqual(snapshots.length, 1);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 6: Legacy user reopens Video Hub -> popup does NOT appear
  await test('TEST 6: Legacy user reopens Video Hub -> needsLanguageSelection = false', async () => {
    const user = await createTestUser({
      emailSuffix: 't6',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      await videoService.setUserLanguage(user.id, englishLang.id);

      const res = await videoService.getUserVideos(user.id);
      assert.strictEqual(res.needsLanguageSelection, false);
      assert.strictEqual(res.assignedLanguage.id, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 7: Legacy user tries select-language again -> HTTP 409 Conflict
  await test('TEST 7: Legacy user tries select-language again -> HTTP 409 Conflict', async () => {
    const user = await createTestUser({
      emailSuffix: 't7',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      await videoService.setUserLanguage(user.id, englishLang.id);

      let errThrown = null;
      try {
        await videoService.setUserLanguage(user.id, hindiLang.id);
      } catch (err) {
        errThrown = err;
      }

      assert.notStrictEqual(errThrown, null);
      assert.strictEqual(errThrown.statusCode, 409);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, englishLang.id);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 8: Admin changes user's language -> languageSelectionRequired remains false
  await test('TEST 8: Admin changes user language -> languageSelectionRequired remains false', async () => {
    const user = await createTestUser({
      emailSuffix: 't8',
      createdAt: oldDate,
      assignedLanguageId: englishLang.id,
      languageSelectionRequired: false,
    });
    try {
      await videoService.assignUserLanguage(user.id, hindiLang.id);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, hindiLang.id);
      assert.strictEqual(profile.languageSelectionRequired, false);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 9: Invalid language ID -> request rejected, no DB mutation
  await test('TEST 9: Invalid language ID -> request rejected, no mutation', async () => {
    const user = await createTestUser({
      emailSuffix: 't9',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      let errThrown = null;
      try {
        await videoService.setUserLanguage(user.id, 'invalid-language-uuid-999');
      } catch (err) {
        errThrown = err;
      }

      assert.notStrictEqual(errThrown, null);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.strictEqual(profile.assignedLanguageId, null);
      assert.strictEqual(profile.languageSelectionRequired, true);

      const snapshots = await prisma.userVideoSnapshot.findMany({ where: { userId: user.id } });
      assert.strictEqual(snapshots.length, 0);
    } finally {
      await cleanupUser(user.id);
    }
  });

  // TEST 10: Concurrent language selection -> exactly 1 assignment, 1 snapshot
  await test('TEST 10: Concurrent language selection -> exactly 1 assignment, 1 snapshot', async () => {
    const user = await createTestUser({
      emailSuffix: 't10',
      createdAt: oldDate,
      assignedLanguageId: null,
      languageSelectionRequired: true,
    });
    try {
      await Promise.allSettled([
        videoService.setUserLanguage(user.id, englishLang.id),
        videoService.setUserLanguage(user.id, hindiLang.id),
      ]);

      const profile = await prisma.profile.findUnique({ where: { userId: user.id } });
      assert.notStrictEqual(profile.assignedLanguageId, null);
      assert.strictEqual(profile.languageSelectionRequired, false);

      const snapshots = await prisma.userVideoSnapshot.findMany({ where: { userId: user.id } });
      assert.strictEqual(snapshots.length, 1);
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
  runLegacyLanguageSelectionTests()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Test suite error:', err);
      process.exit(1);
    });
}

module.exports = runLegacyLanguageSelectionTests;
