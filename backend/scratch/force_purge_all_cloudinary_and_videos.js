const { v2: cloudinary } = require('cloudinary');
const fs = require('fs');
const path = require('path');
const prisma = require('../src/config/database');
const env = require('../src/config/env');

async function forcePurgeAll() {
  console.log('====================================================');
  console.log('🚀 FORCE PURGING ALL VIDEOS & CLOUDINARY ASSETS');
  console.log('====================================================');

  // 1. Purge Dedicated Video Cloudinary Account (qv1eskbe)
  console.log(`\n[1/4] Purging Dedicated Video Cloudinary (${env.CLOUDINARY_VIDEO_CLOUD_NAME})...`);
  if (env.CLOUDINARY_VIDEO_CLOUD_NAME && env.CLOUDINARY_VIDEO_API_KEY && env.CLOUDINARY_VIDEO_API_SECRET) {
    try {
      cloudinary.config({
        cloud_name: env.CLOUDINARY_VIDEO_CLOUD_NAME,
        api_key: env.CLOUDINARY_VIDEO_API_KEY,
        api_secret: env.CLOUDINARY_VIDEO_API_SECRET,
      });

      const videoRes = await cloudinary.api.delete_all_resources({ resource_type: 'video' });
      console.log('  ✅ Video Cloudinary videos deleted:', videoRes);

      const rawRes = await cloudinary.api.delete_all_resources({ resource_type: 'raw' });
      console.log('  ✅ Video Cloudinary raw files deleted:', rawRes);

      const imgRes = await cloudinary.api.delete_all_resources({ resource_type: 'image' });
      console.log('  ✅ Video Cloudinary images deleted:', imgRes);
    } catch (err) {
      console.warn('  ⚠️ Note during Dedicated Cloudinary purge:', err.message);
    }
  } else {
    console.log('  ⚠️ Dedicated Video Cloudinary credentials missing.');
  }

  // 2. Purge Primary Cloudinary Account (lkoedcdp) - Video Folder / Video assets only
  console.log(`\n[2/4] Purging Video Assets from Primary Cloudinary (${env.CLOUDINARY_CLOUD_NAME})...`);
  if (env.CLOUDINARY_CLOUD_NAME && env.CLOUDINARY_API_KEY && env.CLOUDINARY_API_SECRET) {
    try {
      cloudinary.config({
        cloud_name: env.CLOUDINARY_CLOUD_NAME,
        api_key: env.CLOUDINARY_API_KEY,
        api_secret: env.CLOUDINARY_API_SECRET,
      });

      const primaryVideoRes = await cloudinary.api.delete_all_resources({ resource_type: 'video' });
      console.log('  ✅ Primary Cloudinary video resources deleted:', primaryVideoRes);
    } catch (err) {
      console.warn('  ⚠️ Note during Primary Cloudinary video purge:', err.message);
    }
  }

  // 3. Purge Local Temp Upload Folders
  console.log('\n[3/4] Purging Local Upload & Temp Directories...');
  const dirsToClean = [
    path.join(__dirname, '../src/uploads/temp'),
    path.join(__dirname, '../uploads'),
    path.join(__dirname, '../temp'),
  ];

  dirsToClean.forEach((dirPath) => {
    if (fs.existsSync(dirPath)) {
      const files = fs.readdirSync(dirPath);
      files.forEach((file) => {
        if (file !== '.gitkeep') {
          const filePath = path.join(dirPath, file);
          try {
            fs.unlinkSync(filePath);
            console.log(`  🗑️ Deleted local file: ${filePath}`);
          } catch (e) {
            console.warn(`  ⚠️ Could not delete ${filePath}: ${e.message}`);
          }
        }
      });
    }
  });
  console.log('  ✅ Local upload folders clean!');

  // 4. Purge Database Video Tables
  console.log('\n[4/4] Purging Database Video Records...');
  const deletedSnapshotVideos = await prisma.snapshotVideo.deleteMany({});
  console.log(`  🗑️ SnapshotVideo rows deleted: ${deletedSnapshotVideos.count}`);

  const deletedUserSnapshots = await prisma.userVideoSnapshot.deleteMany({});
  console.log(`  🗑️ UserVideoSnapshot rows deleted: ${deletedUserSnapshots.count}`);

  const deletedAssignments = await prisma.videoAssignment.deleteMany({});
  console.log(`  🗑️ VideoAssignment rows deleted: ${deletedAssignments.count}`);

  const deletedProgress = await prisma.userVideoProgress.deleteMany({});
  console.log(`  🗑️ UserVideoProgress rows deleted: ${deletedProgress.count}`);

  const deletedVersions = await prisma.videoVersion.deleteMany({});
  console.log(`  🗑️ VideoVersion rows deleted: ${deletedVersions.count}`);

  const deletedSessions = await prisma.playbackSession.deleteMany({});
  console.log(`  🗑️ PlaybackSession rows deleted: ${deletedSessions.count}`);

  const deletedVideos = await prisma.video.deleteMany({});
  console.log(`  🗑️ Video rows deleted: ${deletedVideos.count}`);

  await prisma.profile.updateMany({
    data: { disclaimerAcceptedAt: null },
  });
  console.log('  🗑️ User profile disclaimer dates reset.');

  console.log('\n====================================================');
  console.log('🎉 ALL VIDEOS & ASSETS FORCIBLY REMOVED EVERYWHERE!');
  console.log('====================================================');

  await prisma.$disconnect();
}

forcePurgeAll().catch((e) => {
  console.error('Fatal Error during purge:', e);
  process.exit(1);
});
