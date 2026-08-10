const prisma = require('../src/config/database');

async function main() {
  console.log('=== SEARCHING FOR ALL VIDEOS IN DATABASE ===');
  const allVideos = await prisma.video.findMany({
    include: { language: true, product: true },
  });
  console.log('Total videos count:', allVideos.length);
  console.log(JSON.stringify(allVideos, null, 2));

  console.log('=== SEARCHING FOR ALL SNAPSHOT VIDEOS ===');
  const snapshotVideos = await prisma.snapshotVideo.findMany();
  console.log('Total snapshotVideos count:', snapshotVideos.length);
  console.log(JSON.stringify(snapshotVideos, null, 2));

  console.log('=== SEARCHING FOR ALL USER SNAPSHOTS ===');
  const userSnapshots = await prisma.userVideoSnapshot.findMany();
  console.log(JSON.stringify(userSnapshots, null, 2));

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
