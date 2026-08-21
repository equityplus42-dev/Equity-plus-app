const assert = require('assert');
const appReleaseService = require('../src/services/appRelease.service');
const cloudflareR2Service = require('../src/services/cloudflareR2.service');
const prisma = require('../src/config/database');

async function testR2ApkReleaseManagement() {
  console.log('🧪 Testing Cloudflare R2 APK Upload, Auto-Cleanup & Download System...');

  try {
    const isR2Configured = cloudflareR2Service.isConfigured();
    console.log(`Cloudflare R2 configured status: ${isR2Configured}`);

    // Create mock APK ZIP buffer (PK\x03\x04 header)
    const mockApkHeader = Buffer.from([0x50, 0x4b, 0x03, 0x04, 0x0a, 0x00, 0x00, 0x00]);
    const mockApkBody = Buffer.alloc(1024 * 1024, 0x65); // 1MB mock APK
    const mockApkBuffer = Buffer.concat([mockApkHeader, mockApkBody]);

    // 1. Upload Release #1
    console.log('Uploading Release v1.0.0...');
    const release1 = await appReleaseService.createRelease('test-admin-id', {
      appType: 'USER_APP',
      platform: 'ANDROID',
      version: '1.0.0',
      buildNumber: 1,
      releaseTitle: 'Initial Release v1.0.0',
      releaseNotes: 'First production build',
    }, mockApkBuffer);

    assert.ok(release1.id, 'Release 1 should be created');
    assert.strictEqual(release1.isActive, true, 'Release 1 should be active');
    console.log(`Release 1 created. downloadUrl: ${release1.downloadUrl}`);

    // 2. Upload Release #2 (Triggers Auto-Cleanup of Release #1 in R2 and DB)
    console.log('Uploading Release v2.0.0 (Should clean up Release v1.0.0)...');
    const release2 = await appReleaseService.createRelease('test-admin-id', {
      appType: 'USER_APP',
      platform: 'ANDROID',
      version: '2.0.0',
      buildNumber: 2,
      releaseTitle: 'Major Release v2.0.0',
      releaseNotes: 'Includes new features',
    }, mockApkBuffer);

    assert.ok(release2.id, 'Release 2 should be created');
    assert.strictEqual(release2.isActive, true, 'Release 2 should be active');
    console.log(`Release 2 created. downloadUrl: ${release2.downloadUrl}`);

    // 3. Verify that old release (v1.0.0) was cleaned up from DB
    const oldReleases = await prisma.appRelease.findMany({
      where: {
        appType: 'USER_APP',
        platform: 'ANDROID',
        version: '1.0.0',
      },
    });
    assert.strictEqual(oldReleases.length, 0, 'Old release v1.0.0 should be deleted from DB after new upload');

    // 4. Test version check
    const checkResult = await appReleaseService.checkVersion({
      appType: 'USER_APP',
      platform: 'ANDROID',
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
    });

    assert.strictEqual(checkResult.updateAvailable, true, 'Update should be available');
    assert.strictEqual(checkResult.latestVersion, '2.0.0', 'Latest version should be 2.0.0');
    assert.ok(checkResult.downloadUrl, 'downloadUrl should be present');
    console.log(`Version check result downloadUrl: ${checkResult.downloadUrl}`);

    console.log('🎉 ALL CLOUDFLARE R2 APK RELEASE TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('❌ Cloudflare R2 APK Release Test Failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testR2ApkReleaseManagement();
