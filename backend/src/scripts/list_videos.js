const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const videos = await prisma.video.findMany({
    select: {
      id: true,
      title: true,
      categoryId: true,
      categoryName: true,
      language: { select: { name: true } },
      category: { select: { name: true } }
    }
  });
  console.log('--- ALL EXISTING VIDEOS IN DB ---');
  console.log(JSON.stringify(videos, null, 2));

  const categories = await prisma.category.findMany();
  console.log('--- ALL CATEGORIES IN DB ---');
  console.log(JSON.stringify(categories, null, 2));
}

main().finally(() => prisma.$disconnect());
