const prisma = require('../config/database');

class AppReleaseRepository {
  async findLatest({ appType = 'USER_APP', platform = 'ANDROID' }) {
    return prisma.appRelease.findFirst({
      where: {
        appType,
        platform,
        isActive: true,
        isLatest: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findById(id) {
    return prisma.appRelease.findUnique({
      where: { id },
    });
  }

  async findByVersionAndBuild({ appType, platform, version, buildNumber }) {
    return prisma.appRelease.findFirst({
      where: {
        appType,
        platform,
        version,
        buildNumber,
      },
    });
  }

  async findAllReleases({ appType, platform, limit = 50, offset = 0 } = {}) {
    const where = {};
    if (appType) where.appType = appType;
    if (platform) where.platform = platform;

    const [total, releases] = await Promise.all([
      prisma.appRelease.count({ where }),
      prisma.appRelease.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
    ]);

    return { total, releases };
  }

  async create(releaseData) {
    return prisma.appRelease.create({
      data: releaseData,
    });
  }

  async update(id, data) {
    return prisma.appRelease.update({
      where: { id },
      data,
    });
  }

  /**
   * Transactional release activation:
   * Demotes any current `isLatest = true` release for (appType, platform) and sets target release to `isActive = true`, `isLatest = true`.
   */
  async activateRelease(id, { appType, platform }) {
    return prisma.$transaction(async (tx) => {
      // 1. Demote current latest release(s) for this appType + platform
      await tx.appRelease.updateMany({
        where: {
          appType,
          platform,
          isLatest: true,
        },
        data: {
          isLatest: false,
        },
      });

      // 2. Promote target release
      const activated = await tx.appRelease.update({
        where: { id },
        data: {
          isActive: true,
          isLatest: true,
        },
      });

      return activated;
    });
  }

  async deactivateRelease(id) {
    return prisma.appRelease.update({
      where: { id },
      data: {
        isActive: false,
        isLatest: false,
      },
    });
  }

  /**
   * Rollback to a specific previous release
   */
  async rollbackRelease(targetId, { appType, platform }) {
    return this.activateRelease(targetId, { appType, platform });
  }

  async deleteRelease(id) {
    return prisma.appRelease.delete({
      where: { id },
    });
  }
}

module.exports = new AppReleaseRepository();
