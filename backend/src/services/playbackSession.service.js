const { v4: uuidv4 } = require('uuid');
const prisma = require('../config/database');
const videoService = require('./video.service');

class PlaybackSessionService {
  async startSession({ userId, videoId, deviceId, deviceName, platform, ipAddress }) {
    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      throw new Error('Video not found');
    }

    // Verify video is unlocked for user
    const userVideoData = await videoService.getUserVideos(userId);
    const isUnlocked = userVideoData.unlockedVideos.some((v) => v.id === videoId);
    if (!isUnlocked) {
      const err = new Error('Video is currently locked. Complete 25% learning progress or wait 30 days to unlock.');
      err.statusCode = 403;
      throw err;
    }

    const sessionId = `SESS_${uuidv4()}`;

    const session = await prisma.playbackSession.create({
      data: {
        sessionId,
        userId,
        videoId,
        deviceId: deviceId || null,
        deviceName: deviceName || null,
        platform: platform || null,
        ipAddress: ipAddress || null,
        startedAt: new Date(),
        watchSeconds: 0,
        lastPositionSecs: 0,
      },
    });

    return session;
  }

  async pingSession(sessionId, { watchSeconds, lastPositionSecs, pauseCount, resumeCount, seekCount, backgroundCount, networkInterruptions }) {
    const session = await prisma.playbackSession.findUnique({ where: { sessionId } });
    if (!session) {
      throw new Error('Playback session not found');
    }

    const updated = await prisma.playbackSession.update({
      where: { sessionId },
      data: {
        watchSeconds: (session.watchSeconds || 0) + (watchSeconds || 0),
        lastPositionSecs: lastPositionSecs !== undefined ? lastPositionSecs : session.lastPositionSecs,
        pauseCount: (session.pauseCount || 0) + (pauseCount || 0),
        resumeCount: (session.resumeCount || 0) + (resumeCount || 0),
        seekCount: (session.seekCount || 0) + (seekCount || 0),
        backgroundCount: (session.backgroundCount || 0) + (backgroundCount || 0),
        networkInterruptions: (session.networkInterruptions || 0) + (networkInterruptions || 0),
      },
    });

    // Also update user progress with lastPositionSecs / watchSeconds
    if (lastPositionSecs !== undefined) {
      await videoService.recordProgress(session.userId, session.videoId, lastPositionSecs);
    }

    return updated;
  }

  async endSession(sessionId, { closedNormally = true, lastPositionSecs }) {
    const session = await prisma.playbackSession.findUnique({ where: { sessionId } });
    if (!session) {
      throw new Error('Playback session not found');
    }

    const updated = await prisma.playbackSession.update({
      where: { sessionId },
      data: {
        endedAt: new Date(),
        closedNormally,
        lastPositionSecs: lastPositionSecs !== undefined ? lastPositionSecs : session.lastPositionSecs,
      },
    });

    if (lastPositionSecs !== undefined) {
      await videoService.recordProgress(session.userId, session.videoId, lastPositionSecs);
    }

    return updated;
  }

  async getLatestUserSessionPosition(userId, videoId) {
    const progress = await prisma.userVideoProgress.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });

    return {
      videoId,
      lastPositionSecs: progress ? progress.watchedSecs : 0,
      isCompleted: progress ? progress.isCompleted : false,
    };
  }
}

module.exports = new PlaybackSessionService();
