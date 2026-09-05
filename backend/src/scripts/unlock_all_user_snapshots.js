const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Unlocking all existing UserVideoSnapshots in production DB...');

  const result = await prisma.userVideoSnapshot.updateMany({
    data: {
      newVideosUnlocked: true
    }
  });

  console.log(`Successfully updated ${result.count} user snapshots to newVideosUnlocked: true.`);
}

main()
  .catch((e) => {
    console.error('Error unlocking snapshots:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
