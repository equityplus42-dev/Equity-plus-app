const prisma = require('../config/database');

class LanguageService {
  /**
   * Get all languages
   */
  async getAllLanguages() {
    try {
      const count = await prisma.language.count();
      if (count === 0) {
        await this.seedDefaults();
      }
    } catch (err) {
      console.error('Language count check error:', err.message);
    }

    return prisma.language.findMany({
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: {
            videos: { where: { isActive: true } },
            profiles: true,
          },
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
      try {
        const existing = await prisma.language.findFirst({
          where: {
            OR: [{ code: lang.code }, { name: lang.name }],
          },
        });
        if (!existing) {
          await prisma.language.create({ data: lang });
        }
      } catch (e) {
        console.error(`Failed to seed default language ${lang.name}:`, e.message);
      }
    }
  }

  /**
   * Create a custom language
   */
  async createLanguage({ name, code }) {
    if (!name || typeof name !== 'string' || !name.trim()) {
      const error = new Error('Language name is required');
      error.statusCode = 400;
      throw error;
    }

    const cleanName = name.trim();
    const cleanCode = (code && typeof code === 'string' && code.trim() ? code.trim() : cleanName.substring(0, 3)).toLowerCase();

    const existingName = await prisma.language.findFirst({
      where: { name: { equals: cleanName } },
    });
    if (existingName) {
      const error = new Error(`Language "${cleanName}" already exists`);
      error.statusCode = 400;
      throw error;
    }

    const existingCode = await prisma.language.findFirst({
      where: { code: { equals: cleanCode } },
    });
    if (existingCode) {
      const error = new Error(`Language code "${cleanCode}" already exists`);
      error.statusCode = 400;
      throw error;
    }

    try {
      return await prisma.language.create({
        data: {
          name: cleanName,
          code: cleanCode,
        },
      });
    } catch (dbErr) {
      if (dbErr.code === 'P2002') {
        const error = new Error('Language with this name or code already exists');
        error.statusCode = 400;
        throw error;
      }
      throw dbErr;
    }
  }

  /**
   * Delete language by ID
   */
  async deleteLanguage(id) {
    const lang = await prisma.language.findUnique({ where: { id } });
    if (!lang) {
      const error = new Error('Language not found');
      error.statusCode = 404;
      throw error;
    }

    try {
      return await prisma.language.delete({
        where: { id },
      });
    } catch (dbErr) {
      if (dbErr.code === 'P2003') {
        const error = new Error('Cannot delete language because videos or profiles are associated with it');
        error.statusCode = 400;
        throw error;
      }
      throw dbErr;
    }
  }
}

module.exports = new LanguageService();
