const prisma = require('../src/config/database');

async function debugState() {
  console.log('=== 1. LANGUAGES IN SYSTEM ===');
  const languages = await prisma.language.findMany();
  console.log(JSON.stringify(languages, null, 2));

  console.log('=== 2. ALL VIDEOS IN DATABASE ===');
  const videos = await prisma.video.findMany({
    include: { language: true, product: true },
  });
  console.log(`Total active/inactive videos: ${videos.length}`);
  console.log(JSON.stringify(videos, null, 2));

  console.log('=== 3. ALL USERS & PROFILES ===');
  const users = await prisma.user.findMany({
    include: {
      profile: { include: { assignedLanguage: true } },
      videoSnapshot: { include: { snapshotVideos: { include: { video: true } } } },
    },
  });
  console.log(JSON.stringify(users.map(u => ({
    id: u.id,
    email: u.email,
    assignedLanguage: u.profile?.assignedLanguage?.name,
    snapshotLanguageId: u.videoSnapshot?.languageId,
    snapshotVideoCount: u.videoSnapshot?.snapshotVideoCount,
    snapshotVideos: u.videoSnapshot?.snapshotVideos.map(sv => ({
      snapshotVideoId: sv.id,
      videoId: sv.videoId,
      videoTitle: sv.video?.title,
      videoIsActive: sv.video?.isActive,
      videoStatus: sv.video?.status,
    }))
  })), null, 2));

  await prisma.$disconnect();
}

debugState().catch((e) => {
  console.error(e);
  process.exit(1);
});
