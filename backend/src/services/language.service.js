const prisma = require('../config/database');

class LanguageService {
  /**
   * Get all languages
   */
  async getAllLanguages() {
    // Seed defaults if empty
    const count = await prisma.language.count();
    if (count === 0) {
      await this.seedDefaults();
    }

    return prisma.language.findMany({
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: { videos: true, profiles: true },
        },
      },
    });
  }

  /**
   * Seed default languages (English, Hindi, Bengali)
   */
  async seedDefaults() {
    const defaults = [
      { name: 'English', code: 'en', isDefault: true },
      { name: 'Hindi', code: 'hi', isDefault: false },
      { name: 'Bengali', code: 'bn', isDefault: false },
    ];

    for (const lang of defaults) {
      await prisma.language.upsert({
        where: { code: lang.code },
        update: {},
        create: lang,
      });
    }
  }

  /**
   * Create a custom language
   */
  async createLanguage({ name, code }) {
    const existingName = await prisma.language.findUnique({ where: { name } });
    if (existingName) {
      throw new Error('Language with this name already exists');
    }

    const cleanCode = (code || name.substring(0, 3)).toLowerCase().trim();
    const existingCode = await prisma.language.findUnique({ where: { code: cleanCode } });
    if (existingCode) {
      throw new Error('Language code already exists');
    }

    return prisma.language.create({
      data: {
        name: name.trim(),
        code: cleanCode,
      },
    });
  }

  /**
   * Delete language by ID
   */
  async deleteLanguage(id) {
    const lang = await prisma.language.findUnique({ where: { id } });
    if (!lang) {
      throw new Error('Language not found');
    }

    return prisma.language.delete({
      where: { id },
    });
  }
}

module.exports = new LanguageService();
