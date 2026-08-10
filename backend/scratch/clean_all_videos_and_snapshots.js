const prisma = require('../src/config/database');

async function cleanAll() {
  console.log('=== CLEANING ALL VIDEOS AND SNAPSHOTS ===');

  // 1. Delete all snapshot videos
  const deletedSnapshotVideos = await prisma.snapshotVideo.deleteMany({});
  console.log(`Deleted ${deletedSnapshotVideos.count} snapshotVideo rows.`);

  // 2. Delete all user video snapshots
  const deletedUserSnapshots = await prisma.userVideoSnapshot.deleteMany({});
  console.log(`Deleted ${deletedUserSnapshots.count} userVideoSnapshot rows.`);

  // 3. Delete all video assignments
  const deletedAssignments = await prisma.videoAssignment.deleteMany({});
  console.log(`Deleted ${deletedAssignments.count} videoAssignment rows.`);

  // 4. Delete all video progress
  const deletedProgress = await prisma.userVideoProgress.deleteMany({});
  console.log(`Deleted ${deletedProgress.count} userVideoProgress rows.`);

  // 5. Delete all video versions
  const deletedVersions = await prisma.videoVersion.deleteMany({});
  console.log(`Deleted ${deletedVersions.count} videoVersion rows.`);

  // 6. Delete all playback sessions
  const deletedSessions = await prisma.playbackSession.deleteMany({});
  console.log(`Deleted ${deletedSessions.count} playbackSession rows.`);

  // 7. Delete all videos from Video table
  const deletedVideos = await prisma.video.deleteMany({});
  console.log(`Deleted ${deletedVideos.count} video rows.`);

  // 8. Reset disclaimerAcceptedAt for all profiles
  await prisma.profile.updateMany({
    data: { disclaimerAcceptedAt: null },
  });
  console.log('Reset disclaimerAcceptedAt for all profiles.');

  console.log('✅ ALL VIDEO AND SNAPSHOT DATA CLEANED 100%!');

  await prisma.$disconnect();
}

cleanAll().catch((e) => {
  console.error(e);
  process.exit(1);
});
