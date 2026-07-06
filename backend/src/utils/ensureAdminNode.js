const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function ensureAdminNodes() {
  try {
    console.log('Checking for admins without hierarchy nodes...');
    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN' },
    });

    for (const admin of admins) {
      const existingNode = await prisma.hierarchyNode.findUnique({
        where: { userId: admin.id },
      });

      if (!existingNode) {
        console.log(`Creating hierarchy node for admin: ${admin.email}`);
        await prisma.hierarchyNode.create({
          data: {
            userId: admin.id,
            parentId: null,
            path: `/${admin.id}`,
            level: 0,
          },
        });
      } else {
        console.log(`Admin ${admin.email} already has a hierarchy node.`);
      }
    }
    console.log('Admin hierarchy check complete.');
  } catch (error) {
    console.error('Error ensuring admin nodes:', error);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  ensureAdminNodes();
}

module.exports = ensureAdminNodes;
