const prisma = require('../src/config/database');

async function main() {
  console.log('=== ALL VIDEOS IN DB ===');
  const videos = await prisma.video.findMany({
    include: { language: true, product: true },
  });
  console.log(JSON.stringify(videos, null, 2));

  console.log('=== ALL SNAPSHOT VIDEOS IN DB ===');
  const snapshotVideos = await prisma.snapshotVideo.findMany();
  console.log(JSON.stringify(snapshotVideos, null, 2));

  console.log('=== ALL USER SNAPSHOTS IN DB ===');
  const snapshots = await prisma.userVideoSnapshot.findMany();
  console.log(JSON.stringify(snapshots, null, 2));

  console.log('=== ALL VIDEO ASSIGNMENTS IN DB ===');
  const assignments = await prisma.videoAssignment.findMany();
  console.log(JSON.stringify(assignments, null, 2));

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
