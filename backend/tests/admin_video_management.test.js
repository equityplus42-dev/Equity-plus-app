const assert = require('assert');
const prisma = require('../src/config/database');
const videoService = require('../src/services/video.service');

async function runAdminVideoManagementTests() {
  console.log('🧪 Starting Admin Video Management Integration & Security Tests...\n');

  try {
    // Step 1: Fetch/Create default language for test
    let lang = await prisma.language.findFirst({ where: { code: 'en' } });
    if (!lang) {
      lang = await prisma.language.create({ data: { name: 'English Test', code: 'en' } });
    }

    // Step 2: Test Create Video 1
    const v1 = await videoService.createVideo({
      title: 'Admin Test Video 1',
      description: 'Test Video 1 Description',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      languageId: lang.id,
      duration: 120,
    });
    assert.ok(v1.id);
    console.log(`✅ Test 1 Passed: Create Video 1 (orderIndex: ${v1.orderIndex})`);

    // Step 3: Test Create Video 2 (Dynamic orderIndex = v1.orderIndex + 1)
    const v2 = await videoService.createVideo({
      title: 'Admin Test Video 2',
      description: 'Test Video 2 Description',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      languageId: lang.id,
      duration: 180,
    });
    assert.ok(v2.id);
    assert.strictEqual(v2.orderIndex, v1.orderIndex + 1);
    console.log(`✅ Test 2 Passed: Dynamic orderIndex calculation (v1=${v1.orderIndex} -> v2=${v2.orderIndex})`);

    // Step 4: Admin Video List returns active videos
    const activeVideos = await videoService.getAllVideosAdmin(lang.id);
    const hasV1 = activeVideos.some((v) => v.id === v1.id);
    const hasV2 = activeVideos.some((v) => v.id === v2.id);
    assert.strictEqual(hasV1, true);
    assert.strictEqual(hasV2, true);
    console.log('✅ Test 3 Passed: getAllVideosAdmin returns active videos');

    // Step 5: Delete Video 1 (Unprotected -> Hard Delete)
    await videoService.deleteVideo(v1.id);
    const activeVideosAfterDelete = await videoService.getAllVideosAdmin(lang.id);
    const hasV1AfterDelete = activeVideosAfterDelete.some((v) => v.id === v1.id);
    assert.strictEqual(hasV1AfterDelete, false);
    console.log('✅ Test 4 Passed: Hard-deleted video is removed from getAllVideosAdmin');

    // Step 6: Soft-Delete Video 2 (Simulate snapshot protection)
    await prisma.video.update({
      where: { id: v2.id },
      data: { isActive: false, status: 'ARCHIVED' },
    });
    const activeVideosAfterSoftDelete = await videoService.getAllVideosAdmin(lang.id);
    const hasV2AfterSoftDelete = activeVideosAfterSoftDelete.some((v) => v.id === v2.id);
    assert.strictEqual(hasV2AfterSoftDelete, false);
    console.log('✅ Test 5 Passed: Soft-deleted/archived video is excluded from default getAllVideosAdmin');

    // Step 7: Cleanup test rows
    await prisma.video.deleteMany({ where: { id: { in: [v1.id, v2.id] } } });

    console.log('\n🎉 ALL ADMIN VIDEO MANAGEMENT TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('❌ Admin Video Management Test Failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runAdminVideoManagementTests();
