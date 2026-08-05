const playbackSessionService = require('../services/playbackSession.service');
const ApiResponse = require('../utils/apiResponse');

class PlaybackSessionController {
  async startSession(req, res, next) {
    try {
      const { videoId } = req.params;
      const { deviceId, deviceName, platform } = req.body;
      const ipAddress = req.ip || req.headers['x-forwarded-for'];
      const session = await playbackSessionService.startSession({
        userId: req.user.id,
        videoId,
        deviceId,
        deviceName,
        platform,
        ipAddress,
      });
      return ApiResponse.success(res, 'Playback session started', session, 201);
    } catch (error) {
      next(error);
    }
  }

  async pingSession(req, res, next) {
    try {
      const { sessionId } = req.params;
      const { watchSeconds, lastPositionSecs, pauseCount, resumeCount, seekCount, backgroundCount, networkInterruptions } = req.body;
      const updated = await playbackSessionService.pingSession(sessionId, {
        watchSeconds,
        lastPositionSecs,
        pauseCount,
        resumeCount,
        seekCount,
        backgroundCount,
        networkInterruptions,
      });
      return ApiResponse.success(res, 'Session pinged', updated);
    } catch (error) {
      next(error);
    }
  }

  async endSession(req, res, next) {
    try {
      const { sessionId } = req.params;
      const { closedNormally, lastPositionSecs } = req.body;
      const updated = await playbackSessionService.endSession(sessionId, {
        closedNormally,
        lastPositionSecs,
      });
      return ApiResponse.success(res, 'Session ended', updated);
    } catch (error) {
      next(error);
    }
  }

  async getLatestPosition(req, res, next) {
    try {
      const { videoId } = req.params;
      const pos = await playbackSessionService.getLatestUserSessionPosition(req.user.id, videoId);
      return ApiResponse.success(res, 'Latest position fetched', pos);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PlaybackSessionController();
