const prisma = require('../config/database');

class SettingsRepository {
  async getSettings() {
    return prisma.systemSettings.findMany();
  }

  async findByKey(key) {
    return prisma.systemSettings.findUnique({
      where: { key },
    });
  }

  async upsertSetting(key, value, description) {
    return prisma.systemSettings.upsert({
      where: { key },
      update: { value, description },
      create: { key, value, description },
    });
  }
}

module.exports = new SettingsRepository();
