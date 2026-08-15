/**
 * migrateR2ObjectKeys.js
 *
 * Safe one-time migration script.
 * Finds all Video records where r2ObjectKey IS NULL and videoUrl looks like a Cloudflare R2 URL.
 * Extracts the permanent R2 object key from the URL and stores it in r2ObjectKey.
 *
 * Safe: only adds data, never deletes or modifies videoUrl.
 * Safe: Cloudinary videos are identified and skipped — they are not modified.
 * Safe: Records where extraction fails are reported but not modified.
 *
 * Usage:
 *   cd backend
 *   node scripts/migrateR2ObjectKeys.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const cloudflareR2Service = require('../src/services/cloudflareR2.service');

async function migrateR2ObjectKeys() {
  console.log('\n════════════════════════════════════════════════════════');
  console.log('  VRIDHI — R2 Object Key Migration');
  console.log('  Scans Video table and populates r2ObjectKey field');
  console.log('════════════════════════════════════════════════════════\n');

  // Fetch all videos where r2ObjectKey is not yet set
  const videos = await prisma.video.findMany({
    where: { r2ObjectKey: null },
    select: { id: true, title: true, videoUrl: true, provider: true },
  });

  console.log(`📦 Found ${videos.length} video(s) without r2ObjectKey.\n`);

  let migratedCount = 0;
  let skippedCloudinary = 0;
  let skippedOther = 0;
  const failed = [];

  for (const video of videos) {
    const url = video.videoUrl || '';
    const isR2Url = url.includes('r2.cloudflarestorage.com') || url.includes('.r2.dev');
    const isCloudinaryUrl = url.includes('res.cloudinary.com') || url.includes('cloudinary.com');
    const storedProvider = video.provider || '';

    // Skip Cloudinary videos — they have no R2 object key
    if (isCloudinaryUrl || storedProvider === 'CLOUDINARY') {
      console.log(`  ☁️  SKIP (Cloudinary): "${video.title}" [${video.id}]`);
      skippedCloudinary++;
      continue;
    }

    // Skip non-R2 URLs (YouTube, Cloudflare Stream, etc.)
    if (!isR2Url && storedProvider !== 'CLOUDFLARE_R2') {
      console.log(`  ⏭  SKIP (Non-R2, provider="${storedProvider}"): "${video.title}" [${video.id}]`);
      skippedOther++;
      continue;
    }

    // Attempt extraction
    const objectKey = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);

    if (!objectKey) {
      console.log(`  ❌ FAILED to extract key from: "${video.title}" [${video.id}]`);
      console.log(`     URL: ${url.substring(0, 100)}...`);
      failed.push({ id: video.id, title: video.title, url });
      continue;
    }

    // Persist the extracted key
    await prisma.video.update({
      where: { id: video.id },
      data: {
        r2ObjectKey: objectKey,
        provider: 'CLOUDFLARE_R2', // Ensure provider is correctly set
      },
    });

    console.log(`  ✅ MIGRATED: "${video.title}" [${video.id}]`);
    console.log(`     r2ObjectKey = ${objectKey}`);
    migratedCount++;
  }

  console.log('\n════════════════════════════════════════════════════════');
  console.log('  Migration Complete');
  console.log(`  ✅ Migrated:         ${migratedCount} video(s)`);
  console.log(`  ☁️  Skipped Cloudinary: ${skippedCloudinary} video(s)`);
  console.log(`  ⏭  Skipped Other:    ${skippedOther} video(s)`);
  console.log(`  ❌ Failed:           ${failed.length} video(s)`);

  if (failed.length > 0) {
    console.log('\n⚠️  The following videos could NOT be automatically migrated.');
    console.log('   They require manual r2ObjectKey inspection or re-upload:');
    for (const f of failed) {
      console.log(`   • [${f.id}] "${f.title}"`);
      console.log(`     URL: ${f.url}`);
    }
  }

  console.log('════════════════════════════════════════════════════════\n');
}

migrateR2ObjectKeys()
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
