const prisma = require('../config/database');

class VideoService {
  /**
   * Get current system disclaimer version from SystemSettings (default 1)
   */
  async getSystemDisclaimerVersion() {
    const setting = await prisma.systemSettings.findUnique({
      where: { key: 'videoDisclaimerVersion' },
    });
    if (!setting) {
      await prisma.systemSettings.create({
        data: {
          key: 'videoDisclaimerVersion',
          value: '1',
          description: 'Current video terms disclaimer version',
        },
      });
      return 1;
    }
    return parseInt(setting.value, 10) || 1;
  }

  /**
   * Get or create permanent UserVideoSnapshot on first video hub entry
   */
  async getOrCreateUserSnapshot(userId) {
    let snapshot = await prisma.userVideoSnapshot.findUnique({
      where: { userId },
      include: {
        snapshotVideos: true,
        language: true,
      },
    });

    if (snapshot) {
      return snapshot;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedLanguage: true, assignedProduct: true },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    let languageId = user.profile?.assignedLanguageId;
    if (!languageId) {
      const defaultLang = await prisma.language.findFirst({
        where: { isDefault: true },
      });
      if (defaultLang) {
        languageId = defaultLang.id;
      } else {
        const firstLang = await prisma.language.findFirst({
          orderBy: { createdAt: 'asc' },
        });
        if (firstLang) {
          languageId = firstLang.id;
        } else {
          throw new Error('No language folders available in system');
        }
      }

      // Auto-assign the detected language to the user's profile permanently
      await prisma.profile.upsert({
        where: { userId },
        update: { assignedLanguageId: languageId },
        create: { userId, assignedLanguageId: languageId },
      });
    }

    const activeVideos = await prisma.video.findMany({
      where: {
        languageId,
        isActive: true,
        status: { in: ['AVAILABLE', 'ASSIGNED', 'IN_USE'] },
      },
      orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
    });

    // Only snapshot the FIRST 3 videos — remaining videos unlock after 25% watch progress
    const INITIAL_BATCH_SIZE = 3;
    const snapshotVideos = activeVideos.slice(0, INITIAL_BATCH_SIZE);

    const snapshotVideoCount = snapshotVideos.length;
    const snapshotTotalDurationSeconds = snapshotVideos.reduce(
      (sum, v) => sum + (v.duration && v.duration > 0 ? v.duration : 60),
      0
    );
    const systemDisclaimerVer = await this.getSystemDisclaimerVersion();

    snapshot = await prisma.userVideoSnapshot.create({
      data: {
        userId,
        languageId,
        snapshotVideoCount,
        snapshotTotalDurationSeconds,
        refundThresholdPercentage: 25,
        refundEligible: true,
        newVideosUnlocked: false,
        disclaimerVersion: systemDisclaimerVer,
        acceptedDisclaimerAt: user.profile?.disclaimerAcceptedAt || null,
        snapshotVideos: {
          create: snapshotVideos.map((v) => ({
            videoId: v.id,
            videoDurationSeconds: v.duration && v.duration > 0 ? v.duration : 60,
          })),
        },
      },
      include: {
        snapshotVideos: true,
        language: true,
      },
    });

    return snapshot;
  }

  /**
   * Helper to check and enforce refund status & auto-unlocking
   */
  async evaluateRefundAndUnlockStatus(userId, snapshot, totalWatchedSecs, daysJoined) {
    const totalSnapshotDuration = snapshot.snapshotTotalDurationSeconds;
    const overallProgress = totalSnapshotDuration > 0
      ? (totalWatchedSecs / totalSnapshotDuration) * 100
      : 0;

    const isProgressThresholdMet = overallProgress >= 25;
    const is30DaysPassed = daysJoined >= 30;

    let updatedSnapshot = snapshot;

    if ((isProgressThresholdMet || is30DaysPassed) && snapshot.refundEligible) {
      updatedSnapshot = await prisma.userVideoSnapshot.update({
        where: { id: snapshot.id },
        data: {
          refundEligible: false,
          refundLostAt: new Date(),
          newVideosUnlocked: true,
        },
        include: {
          snapshotVideos: true,
          language: true,
        },
      });
    } else if ((isProgressThresholdMet || is30DaysPassed) && !snapshot.newVideosUnlocked) {
      updatedSnapshot = await prisma.userVideoSnapshot.update({
        where: { id: snapshot.id },
        data: {
          newVideosUnlocked: true,
        },
        include: {
          snapshotVideos: true,
          language: true,
        },
      });
    }

    return {
      snapshot: updatedSnapshot,
      overallProgress: Math.min(Math.round(overallProgress * 100) / 100, 100),
      isProgressThresholdMet,
      is30DaysPassed,
    };
  }

  /**
   * Fetch videos and progress for user (Unlocked vs Locked) with search and filtering
   */
  async getUserVideos(userId, queryOptions = {}) {
    const { query, filter, sortBy } = queryOptions;
    let snapshot = await this.getOrCreateUserSnapshot(userId);
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedProduct: true },
        },
      },
    });

    const now = new Date();
    const joinedAt = new Date(user.createdAt);
    const daysJoined = Math.floor(Math.abs(now - joinedAt) / (1000 * 60 * 60 * 24));
    const rawSnapshotVideoIds = snapshot.snapshotVideos.map((sv) => sv.videoId);

    // Cross-reference snapshot IDs with live Video table to strip deleted/deactivated videos
    // This ensures users never see stale references to videos the admin has deleted.
    const activeSnapshotRecords = await prisma.video.findMany({
      where: {
        id: { in: rawSnapshotVideoIds },
        isActive: true,
      },
      select: { id: true, duration: true },
    });
    const snapshotVideoIds = activeSnapshotRecords.map((v) => v.id);
    const videoDurationMap = new Map(
      activeSnapshotRecords.map((v) => [v.id, v.duration && v.duration > 0 ? v.duration : 0])
    );

    // Fetch active manual assignments for this user
    const activeDirectAssignments = await prisma.videoAssignment.findMany({
      where: { userId, status: 'ACTIVE' },
      select: { videoId: true },
    });
    const directAssignedVideoIds = new Set(activeDirectAssignments.map((a) => a.videoId));

    // AUTO-REFILL: If some snapshot videos were deactivated/deleted by admin or snapshot had fewer than 3 videos,
    // promote newly uploaded active videos to fill the visible slots (up to INITIAL_BATCH_SIZE=3).
    // Persist to DB so user's snapshot is officially updated and stays in sync.
    const INITIAL_BATCH_SIZE = 3;
    const activeSlotCount = snapshotVideoIds.length;

    if (activeSlotCount < INITIAL_BATCH_SIZE && !snapshot.newVideosUnlocked) {
      const rawSnapshotVideoIds = snapshot.snapshotVideos.map((sv) => sv.videoId);
      const refillVideos = await prisma.video.findMany({
        where: {
          languageId: snapshot.languageId,
          isActive: true,
          status: { in: ['AVAILABLE', 'ASSIGNED', 'IN_USE'] },
          // Exclude videos already in snapshot (whether active or not)
          id: { notIn: rawSnapshotVideoIds },
        },
        orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
        take: INITIAL_BATCH_SIZE - activeSlotCount,
        select: { id: true, duration: true },
      });

      for (const rv of refillVideos) {
        await prisma.snapshotVideo.create({
          data: {
            snapshotId: snapshot.id,
            videoId: rv.id,
            videoDurationSeconds: rv.duration && rv.duration > 0 ? rv.duration : 60,
          },
        });
        snapshotVideoIds.push(rv.id);
        videoDurationMap.set(rv.id, rv.duration && rv.duration > 0 ? rv.duration : 0);
      }

      if (refillVideos.length > 0) {
        const updatedSnapshotVideos = await prisma.snapshotVideo.findMany({
          where: { snapshotId: snapshot.id },
        });
        const newTotalDuration = updatedSnapshotVideos.reduce(
          (sum, sv) => sum + sv.videoDurationSeconds,
          0
        );
        snapshot = await prisma.userVideoSnapshot.update({
          where: { id: snapshot.id },
          data: {
            snapshotVideoCount: updatedSnapshotVideos.length,
            snapshotTotalDurationSeconds: newTotalDuration,
          },
          include: {
            snapshotVideos: true,
            language: true,
          },
        });
      }
    }

    // Effective total duration from real video durations (never trust stale snapshotTotalDurationSeconds)
    let effectiveTotalDurationSecs = 0;
    for (const videoId of snapshotVideoIds) {
      effectiveTotalDurationSecs += videoDurationMap.get(videoId) || 0;
    }

    const userProgressRecords = await prisma.userVideoProgress.findMany({
      where: { userId },
    });

    const progressMap = new Map();
    let totalWatchedSecs = 0;

    for (const record of userProgressRecords) {
      progressMap.set(record.videoId, record);
      if (snapshotVideoIds.includes(record.videoId)) {
        const actualDuration = videoDurationMap.get(record.videoId) || 0;
        // Cap watched seconds to actual video duration so you can't exceed 100%
        const effectiveWatched = actualDuration > 0
          ? Math.min(record.watchedSecs, actualDuration)
          : record.watchedSecs;
        totalWatchedSecs += effectiveWatched;
      }
    }

    // Override snapshot's stored duration with dynamically computed value so evaluateRefundAndUnlockStatus
    // always works with accurate data
    if (effectiveTotalDurationSecs > 0 && snapshot.snapshotTotalDurationSeconds !== effectiveTotalDurationSecs) {
      snapshot = { ...snapshot, snapshotTotalDurationSeconds: effectiveTotalDurationSecs };
    }

    const { snapshot: evaluatedSnapshot, overallProgress } = await this.evaluateRefundAndUnlockStatus(
      userId,
      snapshot,
      totalWatchedSecs,
      daysJoined
    );

    const systemDisclaimerVer = await this.getSystemDisclaimerVersion();
    const disclaimerNeedsReacceptance =
      !user?.profile?.disclaimerAcceptedAt || evaluatedSnapshot.disclaimerVersion < systemDisclaimerVer;

    const whereClause = {
      languageId: evaluatedSnapshot.languageId,
      isActive: true,
      status: { in: ['AVAILABLE', 'ASSIGNED', 'IN_USE'] },
    };

    if (query && query.trim().length > 0) {
      whereClause.OR = [
        { title: { contains: query.trim(), mode: 'insensitive' } },
        { description: { contains: query.trim(), mode: 'insensitive' } },
      ];
    }

    let orderBy = [{ orderIndex: 'asc' }, { createdAt: 'asc' }];
    if (sortBy === 'NEWEST') orderBy = [{ createdAt: 'desc' }];
    if (sortBy === 'OLDEST') orderBy = [{ createdAt: 'asc' }];

    const allActiveVideos = await prisma.video.findMany({
      where: whereClause,
      orderBy,
      include: { language: true, product: true },
    });

    const unlockedVideos = [];
    const lockedVideos = [];

    for (const v of allActiveVideos) {
      const isSnapshotVideo = snapshotVideoIds.includes(v.id);
      const isDirectAssigned = directAssignedVideoIds.has(v.id);
      const isUnlocked = isSnapshotVideo || isDirectAssigned || evaluatedSnapshot.newVideosUnlocked;
      const prog = progressMap.get(v.id);

      if (isUnlocked) {
        const videoData = {
          id: v.id,
          title: v.title,
          description: v.description,
          videoUrl: v.videoUrl,
          thumbnailUrl: v.thumbnailUrl,
          duration: v.duration,
          languageName: v.language.name,
          productName: v.product?.name || null,
          status: v.status,
          orderIndex: v.orderIndex,
          watchedSecs: prog ? prog.watchedSecs : 0,
          isCompleted: prog ? prog.isCompleted : false,
          isLocked: false,
          unlockNotice: null,
          createdAt: v.createdAt,
        };

        const passesFilter =
          !filter ||
          filter === 'ALL' ||
          (filter === 'COMPLETED' && videoData.isCompleted) ||
          (filter === 'CONTINUE_WATCHING' && videoData.watchedSecs > 0 && !videoData.isCompleted) ||
          (filter === 'UNLOCKED' && !videoData.isLocked);

        if (passesFilter) {
          unlockedVideos.push(videoData);
        }
      } else {
        lockedVideos.push({
          id: v.id,
          title: v.title,
          description: v.description,
          videoUrl: null, // Playback disabled for locked videos
          thumbnailUrl: v.thumbnailUrl,
          duration: v.duration,
          languageName: v.language.name,
          productName: v.product?.name || null,
          status: v.status,
          orderIndex: v.orderIndex,
          isLocked: true,
          unlockNotice: 'Uploaded after your learning snapshot. Unlocks after 25% learning progress or 30 days.',
          createdAt: v.createdAt,
        });
      }
    }

    // Use effectiveTotalDurationSecs (live from Video table) for accurate 25% threshold
    const threshold25Secs = Math.ceil(effectiveTotalDurationSecs * 0.25);
    const remainingSecsTo25Percent = Math.max(0, threshold25Secs - totalWatchedSecs);

    return {
      assignedLanguage: evaluatedSnapshot.language,
      assignedProduct: user.profile?.assignedProduct || null,
      isDisclaimerAccepted: !disclaimerNeedsReacceptance && !!evaluatedSnapshot.acceptedDisclaimerAt,
      disclaimerNeedsReacceptance,
      currentDisclaimerVersion: systemDisclaimerVer,
      userSnapshot: {
        snapshotId: evaluatedSnapshot.id,
        snapshotTakenAt: evaluatedSnapshot.snapshotTakenAt,
        snapshotVideoCount: evaluatedSnapshot.snapshotVideoCount,
        snapshotTotalDurationSeconds: effectiveTotalDurationSecs,
        refundThresholdPercentage: evaluatedSnapshot.refundThresholdPercentage,
        refundEligible: evaluatedSnapshot.refundEligible,
        newVideosUnlocked: evaluatedSnapshot.newVideosUnlocked,
        percentage: overallProgress,
        remainingPercentage: Math.max(0, Math.round((100 - overallProgress) * 100) / 100),
        daysJoined,
        remainingDays: Math.max(0, 30 - daysJoined),
        remainingSecsTo25Percent,
      },
      unlockedVideos,
      lockedVideos,
      videos: unlockedVideos,
    };
  }

  /**
   * Get locked videos — always returns empty; locked videos are hidden from users.
   */
  async getLockedVideos(userId) {
    // Locked videos are intentionally hidden from users until unlocked.
    return [];
  }

  /**
   * Record watch progress for a video (updates UserVideoProgress)
   */
  async recordProgress(userId, videoId, watchedSecs) {
    const snapshot = await this.getOrCreateUserSnapshot(userId);
    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      throw new Error('Video not found');
    }

    // Fetch existing record so we never decrease watchedSecs (e.g. after seeking back)
    let record;
    if (existing) {
      record = await prisma.userVideoProgress.update({
        where: { id: existing.id },
        data: {
          watchedSecs: safeWatched,
          lastWatched: new Date(),
          isCompleted,
        },
      });
    } else {
      try {
        record = await prisma.userVideoProgress.create({
          data: {
            userId,
            videoId,
            watchedSecs: safeWatched,
            isCompleted,
          },
        });
      } catch (err) {
        // Fallback for concurrent request collision (P2002)
        record = await prisma.userVideoProgress.update({
          where: { userId_videoId: { userId, videoId } },
          data: {
            watchedSecs: safeWatched,
            lastWatched: new Date(),
            isCompleted,
          },
        });
      }
    }

    const snapshotVideoIds = snapshot.snapshotVideos.map((sv) => sv.videoId);
    const userProgressRecords = await prisma.userVideoProgress.findMany({
      where: {
        userId,
        videoId: { in: snapshotVideoIds },
      },
    });

    let totalWatchedSecs = 0;
    for (const r of userProgressRecords) {
      const sv = snapshot.snapshotVideos.find((s) => s.videoId === r.videoId);
      const capDuration = sv ? sv.videoDurationSeconds : 0;
      const effectiveWatched = capDuration > 0 ? Math.min(r.watchedSecs, capDuration) : r.watchedSecs;
      totalWatchedSecs += effectiveWatched;
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    const now = new Date();
    const joinedAt = new Date(user.createdAt);
    const daysJoined = Math.floor(Math.abs(now - joinedAt) / (1000 * 60 * 60 * 24));

    await this.evaluateRefundAndUnlockStatus(userId, snapshot, totalWatchedSecs, daysJoined);

    return record;
  }

  /**
   * Seek-Protected Heartbeat Logger (Accepts real session playback delta)
   */
  async recordPlaybackHeartbeat(userId, videoId, sessionWatchedSecs) {
    const existing = await prisma.userVideoProgress.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });

    const currentWatched = existing ? existing.watchedSecs : 0;
    const newWatched = currentWatched + Math.max(0, Math.min(sessionWatchedSecs, 10));

    return this.recordProgress(userId, videoId, newWatched);
  }

  /**
   * Secure Video Access Authorization Check
   */
  async getSecureVideoPlayback(userId, videoId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });

    if (!user || !user.isApproved || user.isDeleted) {
      throw new Error('Unauthorized or suspended user account');
    }

    const video = await prisma.video.findUnique({
      where: { id: videoId },
      include: { language: true, product: true },
    });

    if (!video || !video.isActive) {
      throw new Error('Video unavailable or inactive');
    }

    // Verify language assignment
    if (user.profile?.assignedLanguageId && user.profile.assignedLanguageId !== video.languageId) {
      throw new Error('Video language does not match user assigned language');
    }

    // Verify product access authorization server-side
    if (video.productId) {
      const productAccessService = require('./productAccess.service');
      const hasAccess = await productAccessService.hasActiveAccess(userId, video.productId);
      if (!hasAccess) {
        throw new Error('Active product access required to stream this video');
      }
    }

    // Verify snapshot permission
    const snapshot = await this.getOrCreateUserSnapshot(userId);
    const isSnapshotVideo = snapshot.snapshotVideos.some((sv) => sv.videoId === videoId);

    if (!isSnapshotVideo && !snapshot.newVideosUnlocked) {
      throw new Error('Video is locked until 25% learning progress or 30 days');
    }

    return {
      videoId: video.id,
      title: video.title,
      videoUrl: video.videoUrl,
      playbackToken: `SECURE_STREAM_${video.id}_${Date.now()}`,
    };
  }

  /**
   * Get detailed Progress & Refund status payload
   */
  async getProgressStatus(userId) {
    const data = await this.getUserVideos(userId);
    return {
      assignedLanguage: data.assignedLanguage,
      assignedProduct: data.assignedProduct,
      snapshot: data.snapshot,
      progress: data.progress,
      eligible: data.snapshot.refundEligible,
      unlocked: data.snapshot.newVideosUnlocked,
      remainingPercentage: data.progress.remainingPercentage,
      remainingSeconds: Math.max(0, data.progress.totalSnapshotDurationSecs - data.progress.totalWatchedSecs),
      remainingDays: data.progress.remainingDays,
      remainingSecsTo25Percent: data.progress.remainingSecsTo25Percent,
    };
  }

  /**
   * User accepts video disclaimer
   */
  async acceptDisclaimer(userId) {
    const snapshot = await this.getOrCreateUserSnapshot(userId);
    const systemDisclaimerVer = await this.getSystemDisclaimerVersion();
    const now = new Date();

    await prisma.userVideoSnapshot.update({
      where: { id: snapshot.id },
      data: {
        acceptedDisclaimerAt: now,
        disclaimerVersion: systemDisclaimerVer,
      },
    });

    const profile = await prisma.profile.findUnique({ where: { userId } });
    if (!profile) {
      await prisma.profile.create({
        data: { userId, disclaimerAcceptedAt: now },
      });
    } else {
      await prisma.profile.update({
        where: { userId },
        data: { disclaimerAcceptedAt: now },
      });
    }

    return { success: true, message: 'Disclaimer accepted successfully' };
  }

  /**
   * Create video under chosen language & product
   */
  async createVideo({ title, description, videoUrl, thumbnailUrl, duration, languageId, productId, status = 'AVAILABLE', orderIndex }) {
    const language = await prisma.language.findUnique({ where: { id: languageId } });
    if (!language) {
      throw new Error('Specified language folder not found');
    }

    let finalOrderIndex = orderIndex !== undefined && orderIndex !== null ? parseInt(orderIndex, 10) : null;
    if (finalOrderIndex === null || isNaN(finalOrderIndex)) {
      const maxVideo = await prisma.video.findFirst({
        where: { languageId, isActive: true },
        orderBy: { orderIndex: 'desc' },
        select: { orderIndex: true },
      });
      finalOrderIndex = maxVideo ? maxVideo.orderIndex + 1 : 0;
    }

    return prisma.video.create({
      data: {
        title,
        description,
        videoUrl,
        thumbnailUrl: thumbnailUrl || null,
        duration: duration ? parseInt(duration, 10) : 0,
        languageId,
        productId: productId || null,
        status,
        orderIndex: finalOrderIndex,
      },
      include: { language: true, product: true },
    });
  }

  /**
   * Reorder videos (Updates orderIndex)
   */
  async reorderVideos(videoOrders) {
    if (!Array.isArray(videoOrders)) {
      throw new Error('videoOrders must be an array of { id, orderIndex }');
    }

    for (const vo of videoOrders) {
      await prisma.video.update({
        where: { id: vo.id },
        data: { orderIndex: parseInt(vo.orderIndex, 10) || 0 },
      });
    }

    return { success: true, message: 'Video order updated successfully' };
  }

  /**
   * Admin view of all videos (Includes assigned snapshot protection check)
   */
  async getAllVideosAdmin(languageId, includeArchived = false) {
    const where = {};
    if (languageId) {
      where.languageId = languageId;
    }
    if (!includeArchived) {
      where.isActive = true;
      where.status = { not: 'ARCHIVED' };
    }

    const videos = await prisma.video.findMany({
      where,
      orderBy: [{ languageId: 'asc' }, { orderIndex: 'asc' }, { createdAt: 'desc' }],
      include: { language: true, product: true },
    });

    const assignedVideoIds = (
      await prisma.snapshotVideo.findMany({
        distinct: ['videoId'],
        select: { videoId: true },
      })
    ).map((sv) => sv.videoId);

    return videos.map((v) => ({
      ...v,
      isAssignedToSnapshot: assignedVideoIds.includes(v.id),
      deletionProtected: assignedVideoIds.includes(v.id),
    }));
  }

  /**
   * Delete video by ID
   * - If NOT in any user snapshot: hard delete from DB
   * - If IN a user snapshot: soft-delete (set isActive=false) to preserve refund audit trail
   *   but IMMEDIATELY removes it from user visibility (getUserVideos filters isActive:false)
   */
  async deleteVideo(id) {
    const video = await prisma.video.findUnique({ where: { id } });
    if (!video) {
      throw new Error('Video not found');
    }

    const videoAssignmentService = require('./videoAssignment.service');
    return videoAssignmentService.forceDeleteVideo({
      videoId: id,
      adminId: 'ADMIN',
      reqIp: '127.0.0.1',
      userAgent: 'AdminApp',
    });
  }

  /**
   * Admin assigns user language
   */
  async assignUserLanguage(userId, languageId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    const language = await prisma.language.findUnique({ where: { id: languageId } });
    if (!language) {
      throw new Error('Selected language not found');
    }

    await prisma.profile.upsert({
      where: { userId },
      update: { assignedLanguageId: languageId },
      create: { userId, assignedLanguageId: languageId },
    });

    return {
      message: `Language updated to ${language.name} for user ${user.email}`,
      language,
    };
  }

  /**
   * Admin resets user video progress & snapshot
   */
  async resetUserVideoProgress(userId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new Error('User not found');
    }

    await prisma.userVideoSnapshot.deleteMany({
      where: { userId },
    });

    await prisma.userVideoProgress.deleteMany({
      where: { userId },
    });

    await prisma.profile.updateMany({
      where: { userId },
      data: { disclaimerAcceptedAt: null },
    });

    return {
      success: true,
      message: `Video progress and snapshot reset successfully for user ${user.email}. A fresh snapshot will be taken on next entry.`,
    };
  }

  /**
   * Admin fetches comprehensive user snapshot & analytics
   */
  async getUserSnapshotAdmin(userId) {
    const snapshot = await prisma.userVideoSnapshot.findUnique({
      where: { userId },
      include: {
        snapshotVideos: true,
        language: true,
      },
    });

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedProduct: true, assignedLanguage: true },
        },
      },
    });

    if (!snapshot) {
      return {
        userEmail: user?.email,
        assignedLanguage: user?.profile?.assignedLanguage?.name || 'Default',
        assignedProduct: user?.profile?.assignedProduct?.name || 'None',
        snapshot: null,
      };
    }

    const now = new Date();
    const joinedAt = new Date(user.createdAt);
    const daysJoined = Math.floor(Math.abs(now - joinedAt) / (1000 * 60 * 60 * 24));

    const snapshotVideoIds = snapshot.snapshotVideos.map((sv) => sv.videoId);
    const userProgressRecords = await prisma.userVideoProgress.findMany({
      where: { userId, videoId: { in: snapshotVideoIds } },
    });

    let totalWatchedSecs = 0;
    for (const r of userProgressRecords) {
      const sv = snapshot.snapshotVideos.find((s) => s.videoId === r.videoId);
      const capDuration = sv ? sv.videoDurationSeconds : 0;
      totalWatchedSecs += capDuration > 0 ? Math.min(r.watchedSecs, capDuration) : r.watchedSecs;
    }

    const overallProgress = snapshot.snapshotTotalDurationSeconds > 0
      ? Math.min(Math.round((totalWatchedSecs / snapshot.snapshotTotalDurationSeconds) * 10000) / 100, 100)
      : 0;

    let refundLostReason = 'Eligible';
    if (!snapshot.refundEligible) {
      if (overallProgress >= 25 && daysJoined >= 30) {
        refundLostReason = 'Reached 25%+ watch progress & passed 30 days limit';
      } else if (overallProgress >= 25) {
        refundLostReason = 'Reached 25%+ watch progress threshold';
      } else if (daysJoined >= 30) {
        refundLostReason = 'Completed 30 days join duration';
      }
    }

    return {
      userEmail: user.email,
      assignedLanguage: user.profile?.assignedLanguage?.name || snapshot.language.name,
      assignedProduct: user.profile?.assignedProduct?.name || 'None',
      snapshotId: snapshot.id,
      snapshotTakenAt: snapshot.snapshotTakenAt,
      snapshotVideoCount: snapshot.snapshotVideoCount,
      snapshotTotalDurationSeconds: snapshot.snapshotTotalDurationSeconds,
      refundEligible: snapshot.refundEligible,
      refundLostReason,
      refundLostAt: snapshot.refundLostAt,
      newVideosUnlocked: snapshot.newVideosUnlocked,
      disclaimerVersion: snapshot.disclaimerVersion,
      acceptedDisclaimerAt: snapshot.acceptedDisclaimerAt,
      currentProgressPercentage: overallProgress,
      remainingProgressPercentage: Math.max(0, Math.round((100 - overallProgress) * 100) / 100),
      daysJoined,
    };
  }
}

module.exports = new VideoService();
