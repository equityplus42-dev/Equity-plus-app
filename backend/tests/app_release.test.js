const assert = require('assert');
const appReleaseService = require('../src/services/appRelease.service');
const appReleaseRepository = require('../src/repositories/appRelease.repository');
const prisma = require('../src/config/database');

async function runReleaseTests() {
  console.log('🧪 Testing App Release Management & Version Control System...');

  try {
    // 1. Cleanup test releases
    await prisma.appRelease.deleteMany({
      where: {
        version: { in: ['9.9.0', '9.9.1', '9.9.2', '8.8.0'] },
      },
    });

    // 2. Create User App release
    const userRelease = await appReleaseService.createRelease('test-admin-id', {
      appType: 'USER_APP',
      platform: 'ANDROID',
      version: '9.9.0',
      buildNumber: 90,
      minimumSupportedVersion: '9.0.0',
      minimumSupportedBuildNumber: 1,
      forceUpdate: false,
      releaseTitle: 'User App Test Release',
      releaseNotes: 'Test notes',
      downloadUrl: 'https://vridhi.app/user-9.9.0.apk',
      packageName: 'com.vridhi.userapp',
      sha256Checksum: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    });

    assert.strictEqual(userRelease.version, '9.9.0');
    assert.strictEqual(userRelease.appType, 'USER_APP');
    assert.strictEqual(userRelease.isActive, false);

    // 3. Create Admin App release
    const adminRelease = await appReleaseService.createRelease('test-admin-id', {
      appType: 'ADMIN_APP',
      platform: 'ANDROID',
      version: '8.8.0',
      buildNumber: 80,
      minimumSupportedVersion: '8.0.0',
      minimumSupportedBuildNumber: 1,
      forceUpdate: false,
      releaseTitle: 'Admin App Test Release',
      releaseNotes: 'Admin test notes',
      downloadUrl: 'https://vridhi.app/admin-8.8.0.apk',
      packageName: 'com.vridhi.adminapp',
    });

    assert.strictEqual(adminRelease.version, '8.8.0');
    assert.strictEqual(adminRelease.appType, 'ADMIN_APP');

    // 4. Activate User App Release
    await appReleaseService.activateRelease('test-admin-id', userRelease.id);

    // 5. Verify User App version check
    const checkUser = await appReleaseService.checkVersion({
      appType: 'USER_APP',
      platform: 'ANDROID',
      currentVersion: '9.0.0',
      currentBuildNumber: 1,
    });

    assert.strictEqual(checkUser.updateAvailable, true);
    assert.strictEqual(checkUser.forceUpdate, false);
    assert.strictEqual(checkUser.latestVersion, '9.9.0');

    // 6. Verify Admin App version check does NOT receive User App release
    const checkAdmin = await appReleaseService.checkVersion({
      appType: 'ADMIN_APP',
      platform: 'ANDROID',
      currentVersion: '8.0.0',
      currentBuildNumber: 1,
    });

    // Since admin release is not activated yet, checkAdmin should show no update or return installed version
    assert.notStrictEqual(checkAdmin.latestVersion, '9.9.0');

    // 7. Activate Admin App Release
    await appReleaseService.activateRelease('test-admin-id', adminRelease.id);

    const checkAdminActive = await appReleaseService.checkVersion({
      appType: 'ADMIN_APP',
      platform: 'ANDROID',
      currentVersion: '8.0.0',
      currentBuildNumber: 1,
    });

    assert.strictEqual(checkAdminActive.latestVersion, '8.8.0');

    // 8. Create & Activate a newer User App Force Update Release (9.9.1 min 9.9.1)
    const userForceRelease = await appReleaseService.createRelease('test-admin-id', {
      appType: 'USER_APP',
      platform: 'ANDROID',
      version: '9.9.1',
      buildNumber: 91,
      minimumSupportedVersion: '9.9.1',
      minimumSupportedBuildNumber: 91,
      forceUpdate: true,
      releaseTitle: 'Mandatory Update',
      downloadUrl: 'https://vridhi.app/user-9.9.1.apk',
    });

    await appReleaseService.activateRelease('test-admin-id', userForceRelease.id);

    const checkUserObsolete = await appReleaseService.checkVersion({
      appType: 'USER_APP',
      platform: 'ANDROID',
      currentVersion: '9.0.0',
      currentBuildNumber: 1,
    });

    assert.strictEqual(checkUserObsolete.forceUpdate, true);
    assert.strictEqual(checkUserObsolete.latestVersion, '9.9.1');

    // 9. Transaction test: Ensure ONLY ONE isLatest=true per appType + platform
    const latestUserReleases = await prisma.appRelease.findMany({
      where: { appType: 'USER_APP', platform: 'ANDROID', isLatest: true },
    });
    assert.strictEqual(latestUserReleases.length, 1);
    assert.strictEqual(latestUserReleases[0].id, userForceRelease.id);

    // 10. Clean up test releases
    await prisma.appRelease.deleteMany({
      where: {
        version: { in: ['9.9.0', '9.9.1', '9.9.2', '8.8.0'] },
      },
    });

    console.log('✅ All App Release Management tests passed successfully!');
  } catch (err) {
    console.error('❌ App Release Management tests failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runReleaseTests();
