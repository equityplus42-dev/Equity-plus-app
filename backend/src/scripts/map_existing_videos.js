const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const categories = await prisma.category.findMany();
  const categoryMap = {};
  for (const c of categories) {
    categoryMap[c.name] = c;
  }

  const videos = await prisma.video.findMany();
  console.log(`Found ${videos.length} total videos in database.`);

  let updatedCount = 0;

  for (const video of videos) {
    const title = (video.title || '').toLowerCase();
    let targetCategoryName = null;

    if (title.includes('টাইম') || title.includes('time') || title.includes('সময়')) {
      targetCategoryName = 'Time Management';
    } else if (title.includes('অভ্যাস') || title.includes('habit')) {
      targetCategoryName = 'Habit Building';
    } else if (title.includes('কমিউনিকেশন') || title.includes('যোগাযোগ') || title.includes('communication')) {
      targetCategoryName = 'Communication Skills';
    } else if (title.includes('সোশ্যাল') || title.includes('social')) {
      targetCategoryName = 'Social Media Influence';
    } else if (title.includes('মানসিক') || title.includes('mental') || title.includes('mindset')) {
      targetCategoryName = 'Mental Health & Mindset';
    } else if (title.includes('অর্থ') || title.includes('finance')) {
      targetCategoryName = 'Personal Finance';
    } else if (title.includes('একাধিক') || title.includes('income')) {
      targetCategoryName = 'Multiple Streams of Income';
    } else if (title.includes('প্যারেন্টিং') || title.includes('parenting')) {
      targetCategoryName = 'Parenting & Family';
    } else if (title.includes('গীতা') || title.includes('gita')) {
      targetCategoryName = 'Bhagavad Gita Wisdom';
    }

    if (targetCategoryName && categoryMap[targetCategoryName]) {
      const cat = categoryMap[targetCategoryName];
      await prisma.video.update({
        where: { id: video.id },
        data: {
          categoryId: cat.id,
          categoryName: cat.name
        }
      });
      console.log(`Updated video "${video.title}" -> Category: "${cat.name}"`);
      updatedCount++;
    } else {
      console.log(`Video "${video.title}" did not match automated keyword mapping. Current category: ${video.categoryName}`);
    }
  }

  console.log(`Successfully mapped ${updatedCount} videos to their respective categories.`);
}

main()
  .catch((e) => {
    console.error('Error mapping videos:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
