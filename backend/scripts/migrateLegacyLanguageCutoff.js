const prisma = require('../src/config/database');

/**
 * VRIDHI — Legacy User Language Selection Cutoff Migration
 * 
 * Configurable Cutoff: process.env.LEGACY_LANGUAGE_SELECTION_CUTOFF
 * Default: 2026-08-14T14:40:00.000Z (timestamp when language selection feature was introduced)
 */
async function migrateLegacyLanguageCutoff() {
  const cutoffInput = process.env.LEGACY_LANGUAGE_SELECTION_CUTOFF || '2026-08-14T14:40:00.000Z';
  const cutoffDate = new Date(cutoffInput);

  if (isNaN(cutoffDate.getTime())) {
    console.error(`❌ Invalid cutoff date provided: "${cutoffInput}"`);
    process.exit(1);
  }

  console.log('\n============================================================');
  console.log('  VRIDHI — LEGACY USER LANGUAGE SELECTION MIGRATION');
  console.log(`  Cutoff Timestamp: ${cutoffDate.toISOString()}`);
  console.log('============================================================\n');

  // Step 1: Identify eligible legacy profiles (created BEFORE cutoff AND assignedLanguageId IS NULL)
  const legacyProfiles = await prisma.profile.findMany({
    where: {
      user: {
        createdAt: { lt: cutoffDate },
      },
      assignedLanguageId: null,
    },
    select: { id: true, userId: true, user: { select: { email: true, createdAt: true } } },
  });

  console.log(`🔍 Found ${legacyProfiles.length} legacy account(s) created before cutoff without assigned language:`);
  legacyProfiles.forEach(p => {
    console.log(`   - User: ${p.userId} (${p.user.email}), Created: ${p.user.createdAt.toISOString()}`);
  });

  // Step 2: Mark legacy profiles as languageSelectionRequired = true
  if (legacyProfiles.length > 0) {
    const legacyIds = legacyProfiles.map(p => p.id);
    const updateResult = await prisma.profile.updateMany({
      where: { id: { in: legacyIds } },
      data: { languageSelectionRequired: true },
    });
    console.log(`✅ Set languageSelectionRequired = true for ${updateResult.count} legacy profile(s).`);
  } else {
    console.log('ℹ️ No eligible legacy profiles to update.');
  }

  // Step 3: Normalize all non-eligible profiles to languageSelectionRequired = false
  // (i.e. Profiles created AFTER cutoff OR profiles that ALREADY have assignedLanguageId != null)
  const nonLegacyUpdate = await prisma.profile.updateMany({
    where: {
      OR: [
        { user: { createdAt: { gte: cutoffDate } } },
        { assignedLanguageId: { not: null } },
      ],
    },
    data: { languageSelectionRequired: false },
  });
  console.log(`✅ Set languageSelectionRequired = false for ${nonLegacyUpdate.count} non-legacy profile(s).\n`);

  console.log('============================================================');
  console.log('  MIGRATION COMPLETED SUCCESSFULLY 🎉');
  console.log('============================================================\n');
}

if (require.main === module) {
  migrateLegacyLanguageCutoff()
    .then(() => prisma.$disconnect())
    .catch(err => {
      console.error('Migration failed:', err);
      prisma.$disconnect();
      process.exit(1);
    });
}

module.exports = migrateLegacyLanguageCutoff;
