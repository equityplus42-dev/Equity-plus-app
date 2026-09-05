const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const joiningSnapshotService = require('../services/joiningSnapshot.service');

async function main() {
  const users = await prisma.user.findMany({
    where: { isDeleted: false },
    select: { id: true, email: true }
  });

  console.log(`Backfilling joining snapshots for ${users.length} registered users...`);

  let count = 0;
  for (const u of users) {
    const snap = await joiningSnapshotService.createSnapshotForUser(u.id);
    if (snap) count++;
  }

  console.log(`Successfully created/updated ${count} joining snapshots!`);
}

main()
  .catch((e) => {
    console.error('Error backfilling snapshots:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
