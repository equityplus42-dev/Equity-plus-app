const videoAssignmentService = require('../src/services/videoAssignment.service');
const prisma = require('../src/config/database');

async function main() {
  const targetVideoId = '81daa41d-83aa-4569-833e-ebe0313936cd'; // Video "Test"
  console.log(`Starting force deletion of video "${targetVideoId}"...`);

  try {
    const result = await videoAssignmentService.forceDeleteVideo({
      videoId: targetVideoId,
      adminId: 'SYSTEM_AGENT_OVERRIDE',
      reqIp: '127.0.0.1',
      userAgent: 'Antigravity-Agent',
    });
    console.log('✅ FORCE DELETE SUCCESSFUL!');
    console.log(result);
  } catch (e) {
    console.error('❌ Force delete failed:', e.message);
  }

  // Double check remaining videos in DB
  const remainingVideos = await prisma.video.findMany();
  console.log('Remaining videos in DB count:', remainingVideos.length);
  console.log(remainingVideos);

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
