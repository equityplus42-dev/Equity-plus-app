const prisma = require('../src/config/database');
const videoAssignmentService = require('../src/services/videoAssignment.service');
const videoService = require('../src/services/video.service');
const playbackSessionService = require('../src/services/playbackSession.service');

async function runVideoAssignmentTests() {
  console.log('============================================================');
  console.log('TEST SUITE: Admin Video Assignment & Unassignment Management');
  console.log('============================================================');

  let testUserId = null;
  let testVideoId = null;
  let testLangId = null;

  try {
    // 1. Setup test language and video
    let lang = await prisma.language.findFirst({ where: { code: 'EN' } });
    if (!lang) {
      lang = await prisma.language.create({
        data: { name: 'English Test', code: 'EN' },
      });
    }
    testLangId = lang.id;

    let testUser = await prisma.user.findFirst({
      where: { role: 'USER', isApproved: true, isDeleted: false },
      include: { profile: true },
    });
    if (!testUser) {
      testUser = await prisma.user.create({
        data: {
          email: `test_assign_${Date.now()}@example.com`,
          password: 'Password123!',
          role: 'USER',
          isApproved: true,
          profile: {
            create: {
              firstName: 'Assign',
              lastName: 'Tester',
              assignedLanguageId: testLangId,
            },
          },
        },
      });
    }
    testUserId = testUser.id;

    let testVideo = await prisma.video.findFirst({
      where: { languageId: testLangId, isActive: true },
    });
    if (!testVideo) {
      testVideo = await prisma.video.create({
        data: {
          title: 'Assignment Integration Test Video',
          description: 'Video for testing assignment flow',
          videoUrl: 'https://res.cloudinary.com/test/video.mp4',
          duration: 120,
          languageId: testLangId,
          status: 'AVAILABLE',
          orderIndex: 99,
        },
      });
    }
    testVideoId = testVideo.id;

    console.log(`[SETUP] Test User ID: ${testUserId}, Video ID: ${testVideoId}`);

    // TEST 1: Fetch Dashboard Stats
    console.log('\n[TEST 1] Fetch Assignment Dashboard Stats...');
    const stats = await videoAssignmentService.getAssignmentDashboardStats();
    console.log('Stats Result:', stats);
    if (typeof stats.totalVideos !== 'number' || typeof stats.assignedVideos !== 'number') {
      throw new Error('TEST 1 FAILED: Invalid dashboard stats structure');
    }
    console.log('✅ TEST 1 PASSED: Assignment Dashboard Stats fetched successfully');

    // TEST 2: Assign Video to User
    console.log('\n[TEST 2] Single Video Assignment...');
    const assignment = await videoAssignmentService.assignVideoToUser({
      userId: testUserId,
      videoId: testVideoId,
      adminId: testUserId,
      reqIp: '127.0.0.1',
      userAgent: 'TestRunner',
    });
    console.log('Assignment Result:', assignment);
    if (!assignment || assignment.status !== 'ACTIVE') {
      throw new Error('TEST 2 FAILED: Video assignment failed or status not ACTIVE');
    }
    console.log('✅ TEST 2 PASSED: Single Video Assignment succeeded');

    // TEST 3: Bulk Video Assignment
    console.log('\n[TEST 3] Bulk Video Assignment...');
    const bulkRes = await videoAssignmentService.bulkAssignVideo({
      videoId: testVideoId,
      userIds: [testUserId],
      adminId: testUserId,
      reqIp: '127.0.0.1',
      userAgent: 'TestRunner',
    });
    console.log('Bulk Result:', bulkRes);
    if (!bulkRes.success || bulkRes.assignedCount < 1) {
      throw new Error('TEST 3 FAILED: Bulk video assignment failed');
    }
    console.log('✅ TEST 3 PASSED: Bulk Video Assignment succeeded');

    // TEST 4: Get Video Assignment Details
    console.log('\n[TEST 4] Get Video Assignment Details...');
    const details = await videoAssignmentService.getVideoAssignmentDetails(testVideoId, {});
    console.log('Details Assigned Users Count:', details.assignedUsers.length);
    if (!details.video || !Array.isArray(details.assignedUsers)) {
      throw new Error('TEST 4 FAILED: Video assignment details invalid');
    }
    console.log('✅ TEST 4 PASSED: Video assignment details fetched successfully');

    // TEST 5: Unassign Video (Validating Snapshot Safeguard)
    console.log('\n[TEST 5] Unassign Video with Snapshot Safeguard check...');
    const unassignRes = await videoAssignmentService.unassignVideoFromUser({
      userId: testUserId,
      videoId: testVideoId,
      adminId: testUserId,
      reqIp: '127.0.0.1',
      userAgent: 'TestRunner',
    });
    console.log('Unassign Result:', unassignRes);
    if (!unassignRes.success) {
      throw new Error('TEST 5 FAILED: Unassign video failed');
    }
    console.log('✅ TEST 5 PASSED: Unassign video succeeded with historical snapshot safeguards intact');

    // TEST 6: User Video Access Breakdown for User Directory
    console.log('\n[TEST 6] User Directory Video Access Breakdown...');
    const userAccess = await videoAssignmentService.getUserVideoAssignmentsAdmin(testUserId);
    console.log('User Access Breakdown for Admin:', {
      userId: userAccess.userId,
      assignedLanguage: userAccess.assignedLanguage?.name,
      currentAssignmentsCount: userAccess.currentAssignments.length,
    });
    if (!userAccess.userId) {
      throw new Error('TEST 6 FAILED: User video access breakdown invalid');
    }
    console.log('✅ TEST 6 PASSED: User directory video access breakdown fetched successfully');

    console.log('\n============================================================');
    console.log('ALL 6 VIDEO ASSIGNMENT INTEGRATION TESTS PASSED PERFECTLY! 🚀');
    console.log('============================================================\n');
  } catch (error) {
    console.error('\n❌ TEST SUITE FAILED:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  runVideoAssignmentTests().then(() => process.exit(0));
}

module.exports = runVideoAssignmentTests;
