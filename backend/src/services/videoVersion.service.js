const prisma = require('../config/database');

class VideoVersionService {
  async createVersion(videoId, { title, description, videoUrl, thumbnailUrl, duration, changeLog, createdBy }) {
    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      throw new Error('Video not found');
    }

    const nextVersionNumber = (video.currentVersionNumber || 1) + 1;

    // Create immutable version record
    const versionRecord = await prisma.videoVersion.create({
      data: {
        videoId,
        versionNumber: nextVersionNumber,
        title: title || video.title,
        description: description !== undefined ? description : video.description,
        videoUrl: videoUrl || video.videoUrl,
        thumbnailUrl: thumbnailUrl !== undefined ? thumbnailUrl : video.thumbnailUrl,
        duration: duration ? parseInt(duration, 10) : video.duration,
        changeLog: changeLog || 'Updated video version',
        createdBy: createdBy || 'ADMIN',
      },
    });

    // Update active video pointer to latest version
    await prisma.video.update({
      where: { id: videoId },
      data: {
        currentVersionNumber: nextVersionNumber,
        title: title || video.title,
        description: description !== undefined ? description : video.description,
        videoUrl: videoUrl || video.videoUrl,
        thumbnailUrl: thumbnailUrl !== undefined ? thumbnailUrl : video.thumbnailUrl,
        duration: duration ? parseInt(duration, 10) : video.duration,
      },
    });

    return versionRecord;
  }

  async getVersionHistory(videoId) {
    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      throw new Error('Video not found');
    }

    return prisma.videoVersion.findMany({
      where: { videoId },
      orderBy: { versionNumber: 'desc' },
    });
  }

  async restoreVersion(videoId, versionId) {
    const version = await prisma.videoVersion.findUnique({ where: { id: versionId } });
    if (!version || version.videoId !== videoId) {
      throw new Error('Specified video version not found');
    }

    return prisma.video.update({
      where: { id: videoId },
      data: {
        title: version.title,
        description: version.description,
        videoUrl: version.videoUrl,
        thumbnailUrl: version.thumbnailUrl,
        duration: version.duration,
      },
    });
  }
}

module.exports = new VideoVersionService();
