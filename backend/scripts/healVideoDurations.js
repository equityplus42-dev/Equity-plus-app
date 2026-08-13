require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function healVideoDurations() {
  console.log('🔍 Checking database for videos with duration = 0...');
  try {
    const zeroDurVideos = await prisma.video.findMany({
      where: { duration: 0 },
    });

    if (zeroDurVideos.length === 0) {
      console.log('✅ All videos in database already have valid non-zero durations!');
      return;
    }

    console.log(`📦 Found ${zeroDurVideos.length} video(s) needing duration healing...`);

    for (const v of zeroDurVideos) {
      // Check max watchedSecs from userVideoProgress
      const maxProgress = await prisma.userVideoProgress.aggregate({
        where: { videoId: v.id },
        _max: { watchedSecs: true },
      });

      const maxWatched = maxProgress._max.watchedSecs || 0;
      const healedDuration = maxWatched > 0 ? maxWatched : 60; // Default to maxWatched or 60s fallback

      await prisma.video.update({
        where: { id: v.id },
        data: { duration: healedDuration },
      });

      console.log(`  ✨ Healed Video "${v.title}" (ID: ${v.id}) duration: 0s ➔ ${healedDuration}s`);
    }

    console.log('\n🎉 Successfully healed all video durations in database!');
  } catch (err) {
    console.error('❌ Error healing video durations:', err);
  } finally {
    await prisma.$disconnect();
  }
}

healVideoDurations();
