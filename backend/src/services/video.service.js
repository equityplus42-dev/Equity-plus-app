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

    if (user.isTestUser || user.email === 'test@gmail.com') {
      return null;
    }

    let snapshot = await prisma.userVideoSnapshot.findUnique({
      where: { userId },
      include: {
        snapshotVideos: true,
        language: true,
      },
    });

    if (snapshot) {
      await this.syncUserInitialVideoAssignments(userId, snapshot);
      return snapshot;
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

    // Auto-assign first 3 snapshot videos in VideoAssignment table
    await this.syncUserInitialVideoAssignments(userId, snapshot);

    return snapshot;
  }

  /**
   * Helper to ensure active VideoAssignment records exist for initial/snapshot videos (First 3 videos)
   */
  async syncUserInitialVideoAssignments(userId, snapshot) {
    if (!snapshot || !snapshot.snapshotVideos || snapshot.snapshotVideos.length === 0) {
      return;
    }
    for (const sv of snapshot.snapshotVideos) {
      const vid = sv.videoId;
      const video = await prisma.video.findUnique({ where: { id: vid } });
      if (video && video.isActive) {
        await prisma.videoAssignment.upsert({
          where: { userId_videoId: { userId, videoId: vid } },
          update: { status: 'ACTIVE' },
          create: {
            userId,
            videoId: vid,
            languageId: video.languageId,
            productId: video.productId,
            status: 'ACTIVE',
            assignedBy: 'SYSTEM_AUTO',
          },
        });
      }
    }
  }

  /**
   * Helper to sync initial top 3 video assignments for ALL non-deleted registered users in DB
   */
  async syncAllUsersInitialVideoAssignments() {
    try {
      const users = await prisma.user.findMany({
        where: { role: 'USER', isApproved: true, isDeleted: false },
        select: { id: true },
      });
      for (const u of users) {
        const snap = await this.getOrCreateUserSnapshot(u.id);
        if (snap) {
          await this.syncUserInitialVideoAssignments(u.id, snap);
        }
      }
      console.info(`[VideoService] Successfully synced initial video assignments for ${users.length} users.`);
    } catch (e) {
      console.warn('[VideoService] syncAllUsersInitialVideoAssignments warning:', e.message);
    }
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
   * Set user's chosen language permanently in profile and initialize user video snapshot
   */
  async setUserLanguage(userId, languageId) {
    // Safety guard: this endpoint is ONLY for eligible legacy language selection.
    // Must satisfy BOTH: languageSelectionRequired == true AND assignedLanguageId == null.
    const existingProfile = await prisma.profile.findUnique({ where: { userId } });
    if (!existingProfile || !existingProfile.languageSelectionRequired || existingProfile.assignedLanguageId) {
      const error = new Error(
        'Language selection has already been completed or is not required for this account.'
      );
      error.statusCode = 409;
      throw error;
    }

    const language = await prisma.language.findUnique({ where: { id: languageId } });
    if (!language) {
      throw new Error('Selected language not found');
    }

    // Atomic transaction: save assigned language and clear languageSelectionRequired flag permanently
    await prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { userId },
        data: {
          assignedLanguageId: languageId,
          languageSelectionRequired: false,
        },
      });
    });

    // Create the permanent video snapshot for this selected language
    await this.getOrCreateUserSnapshot(userId);

    // Return the updated user videos payload
    return this.getUserVideos(userId);
  }

  /**
   * Fetch videos and progress for user (Unlocked vs Locked) with search and filtering
   */
  async getUserVideos(userId, queryOptions = {}) {
    const { query, filter, sortBy } = queryOptions;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedProduct: true, assignedLanguage: true },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const isTestUser = Boolean(user.isTestUser || user.email === 'test@gmail.com');

    // DEVELOPER TEST USER OVERRIDE:
    // Can view all language categories and all active videos inside them without any locks
    if (isTestUser) {
      const availableLanguages = await prisma.language.findMany({
        orderBy: [{ name: 'asc' }],
        select: { id: true, name: true, code: true, isDefault: true },
      });

      const { languageId: requestedLanguageId } = queryOptions;
      const whereClause = {
        isActive: true,
        status: { in: ['AVAILABLE', 'ASSIGNED', 'IN_USE'] },
      };

      if (requestedLanguageId) {
        whereClause.languageId = requestedLanguageId;
      }

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

      const userProgressRecords = await prisma.userVideoProgress.findMany({
        where: { userId },
      });
      const progressMap = new Map(userProgressRecords.map((r) => [r.videoId, r]));

      const unlockedVideos = allActiveVideos.map((v) => {
        const prog = progressMap.get(v.id);
        const isR2Video = Boolean(v.r2ObjectKey) ||
          (v.videoUrl && (v.videoUrl.includes('r2.cloudflarestorage.com') || v.videoUrl.includes('.r2.dev')));

        return {
          id: v.id,
          title: v.title,
          description: v.description,
          videoUrl: isR2Video ? null : v.videoUrl,
          thumbnailUrl: v.thumbnailUrl,
          duration: v.duration,
          languageId: v.languageId,
          languageName: v.language.name,
          productName: v.product?.name || null,
          status: v.status,
          orderIndex: v.orderIndex,
          provider: v.provider || (isR2Video ? 'CLOUDFLARE_R2' : 'CLOUDINARY'),
          watchedSecs: prog ? prog.watchedSecs : 0,
          isCompleted: prog ? prog.isCompleted : false,
          isLocked: false,
          unlockNotice: null,
          createdAt: v.createdAt,
        };
      });

      return {
        needsLanguageSelection: false,
        isTestUser: true,
        availableLanguages,
        assignedLanguage: user.profile?.assignedLanguage || availableLanguages[0] || null,
        assignedProduct: user.profile?.assignedProduct || null,
        isDisclaimerAccepted: true,
        disclaimerNeedsReacceptance: false,
        currentDisclaimerVersion: 1,
        userSnapshot: null,
        snapshot: null,
        progress: null,
        unlockedVideos,
        lockedVideos: [],
        videos: unlockedVideos,
      };
    }

    // State 4 Normalization: If languageSelectionRequired is true BUT assignedLanguageId is already set,
    // normalize DB to false safely without altering assignedLanguageId.
    if (user.profile?.languageSelectionRequired && user.profile?.assignedLanguageId) {
      await prisma.profile.update({
        where: { userId },
        data: { languageSelectionRequired: false },
      });
      user.profile.languageSelectionRequired = false;
    }

    // State 1: Legacy user eligible for first-time language selection prompt
    // Popup MUST appear ONLY when BOTH languageSelectionRequired === true AND assignedLanguageId === null
    if (user.profile?.languageSelectionRequired && !user.profile?.assignedLanguageId) {
      const availableLanguages = await prisma.language.findMany({
        orderBy: [{ name: 'asc' }],
        select: { id: true, name: true, code: true, isDefault: true },
      });

      return {
        needsLanguageSelection: true,
        availableLanguages,
        unlockedVideos: [],
        lockedVideos: [],
        assignedLanguage: null,
        assignedProduct: user.profile?.assignedProduct || null,
        userSnapshot: null,
        snapshot: null,
        progress: null,
      };
    }

    // State 3: User has NO assigned language AND languageSelectionRequired === false
    // (e.g. New account, post-cutoff account, or incomplete registration).
    // DO NOT show legacy popup! Return needsLanguageSelection: false.
    if (!user.profile?.assignedLanguageId) {
      return {
        needsLanguageSelection: false,
        availableLanguages: [],
        unlockedVideos: [],
        lockedVideos: [],
        assignedLanguage: null,
        assignedProduct: user.profile?.assignedProduct || null,
        userSnapshot: null,
        snapshot: null,
        progress: null,
      };
    }

    let snapshot = await this.getOrCreateUserSnapshot(userId);

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

    // Fetch manual revocations for this user to exclude explicitly unassigned videos
    const revokedAssignments = await prisma.videoAssignment.findMany({
      where: { userId, status: 'REVOKED' },
      select: { videoId: true },
    });
    const revokedVideoIds = new Set(revokedAssignments.map((a) => a.videoId));

    const whereClause = {
      languageId: evaluatedSnapshot.languageId,
      isActive: true,
      status: { in: ['AVAILABLE', 'ASSIGNED', 'IN_USE'] },
      id: { notIn: Array.from(revokedVideoIds) },
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
        // For R2 videos, omit the stored videoUrl from the library list response.
        // The stored URL is a stale presigned URL that may have expired.
        // Flutter must call GET /videos/:id/access to get a fresh signed URL before playback.
        const isR2Video = Boolean(v.r2ObjectKey) ||
          (v.videoUrl && (v.videoUrl.includes('r2.cloudflarestorage.com') || v.videoUrl.includes('.r2.dev')));
        const videoData = {
          id: v.id,
          title: v.title,
          description: v.description,
          videoUrl: isR2Video ? null : v.videoUrl,  // R2: null (use /access). Cloudinary: direct URL.
          thumbnailUrl: v.thumbnailUrl,
          duration: v.duration,
          languageName: v.language.name,
          productName: v.product?.name || null,
          status: v.status,
          orderIndex: v.orderIndex,
          provider: v.provider || (isR2Video ? 'CLOUDFLARE_R2' : 'CLOUDINARY'),
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
        // Remaining videos stay HIDDEN until 25% watch time criteria or 30 days unlock criteria is met.
      }
    }

    // Use effectiveTotalDurationSecs (live from Video table) for accurate 25% threshold
    const threshold25Secs = Math.ceil(effectiveTotalDurationSecs * 0.25);
    const remainingSecsTo25Percent = Math.max(0, threshold25Secs - totalWatchedSecs);

    const userSnapshotData = {
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
    };

    return {
      needsLanguageSelection: false,
      assignedLanguage: evaluatedSnapshot.language,
      assignedProduct: user.profile?.assignedProduct || null,
      isDisclaimerAccepted: !disclaimerNeedsReacceptance && !!evaluatedSnapshot.acceptedDisclaimerAt,
      disclaimerNeedsReacceptance,
      currentDisclaimerVersion: systemDisclaimerVer,
      userSnapshot: userSnapshotData,
      snapshot: userSnapshotData,
      progress: userSnapshotData,
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
    const existing = await prisma.userVideoProgress.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });
    const safeWatched = Math.max(Math.max(watchedSecs, 0), existing ? existing.watchedSecs : 0);
    const videoDuration = video.duration && video.duration > 0 ? video.duration : 0;
    const isCompleted = videoDuration > 0
      ? safeWatched >= videoDuration * 0.8
      : safeWatched >= 30;

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
   * Secure Video Access Authorization Check + Fresh Playback URL Generation
   *
   * Authorization is ALWAYS checked BEFORE generating any URL.
   * For R2 videos: a NEW short-lived presigned URL is generated on every authorized call.
   * This guarantees users can watch their videos indefinitely as long as authorization holds,
   * regardless of how old the stored videoUrl is.
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

    const isTestUser = Boolean(user.isTestUser || user.email === 'test@gmail.com');

    if (!isTestUser) {
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

      // Check if admin manually revoked access to this video for this user
      const revokedAssignment = await prisma.videoAssignment.findFirst({
        where: { userId, videoId, status: 'REVOKED' },
      });
      if (revokedAssignment) {
        throw new Error('Access to this video has been revoked for your account');
      }

      // Verify snapshot permission and direct assignment
      const snapshot = await this.getOrCreateUserSnapshot(userId);
      const isSnapshotVideo = snapshot.snapshotVideos.some((sv) => sv.videoId === videoId);

      const directAssignment = await prisma.videoAssignment.findFirst({
        where: { userId, videoId, status: 'ACTIVE' },
      });
      const isDirectAssigned = Boolean(directAssignment);

      if (!isSnapshotVideo && !snapshot.newVideosUnlocked && !isDirectAssigned) {
        throw new Error('Video is locked until 25% learning progress or 30 days');
      }
    }

    // ── Determine provider and generate playback URL ──────────────────────────
    // Authorization checks are ALL complete above this line.
    // Now we may generate a fresh URL.

    const cloudflareR2Service = require('./cloudflareR2.service');

    const isR2Video =
      Boolean(video.r2ObjectKey) ||
      (video.videoUrl && (
        video.videoUrl.includes('r2.cloudflarestorage.com') ||
        video.videoUrl.includes('.r2.dev')
      ));

    let playbackUrl = video.videoUrl; // Default: Cloudinary or other non-R2 URL
    let provider = video.provider || (isR2Video ? 'CLOUDFLARE_R2' : 'CLOUDINARY');

    if (isR2Video) {
      // Obtain the permanent object key
      let objectKey = video.r2ObjectKey;

      // If r2ObjectKey is not yet stored, extract it from the URL (legacy migration path)
      if (!objectKey && video.videoUrl) {
        objectKey = cloudflareR2Service.extractR2ObjectKeyFromUrl(video.videoUrl);
        if (objectKey) {
          // Opportunistically persist the extracted key so future requests skip this step
          await prisma.video.update({
            where: { id: videoId },
            data: { r2ObjectKey: objectKey },
          });
          console.info(`[VideoService] Auto-migrated r2ObjectKey for video ${videoId}: ${objectKey}`);
        }
      }

      if (objectKey) {
        // Generate fresh 1-hour signed URL — this is the playback credential
        const freshUrl = await cloudflareR2Service.generatePlaybackUrl(objectKey, 3600);
        if (freshUrl) {
          playbackUrl = freshUrl;
          provider = 'CLOUDFLARE_R2';
        } else {
          console.warn(`[VideoService] Could not generate fresh R2 URL for video ${videoId}. Falling back to stored URL.`);
          // playbackUrl remains video.videoUrl — may be expired, but graceful degradation
        }
      } else {
        console.warn(`[VideoService] No r2ObjectKey could be determined for R2 video ${videoId}. Using stored URL.`);
      }
    }

    return {
      videoId: video.id,
      title: video.title,
      videoUrl: playbackUrl,
      provider,
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
   * @param {string} r2ObjectKey — Permanent R2 object key (e.g. "videos/<uuid>.mp4"). Store this, NOT the presigned URL.
   */
  async createVideo({ title, description, videoUrl, thumbnailUrl, duration, languageId, productId, status = 'AVAILABLE', orderIndex, r2ObjectKey, provider }) {
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

    // Determine provider from explicit param or infer from URL
    let resolvedProvider = provider || 'CLOUDINARY';
    if (!provider && r2ObjectKey) resolvedProvider = 'CLOUDFLARE_R2';
    if (!provider && videoUrl && (videoUrl.includes('r2.cloudflarestorage.com') || videoUrl.includes('.r2.dev'))) {
      resolvedProvider = 'CLOUDFLARE_R2';
    }

    return prisma.video.create({
      data: {
        title,
        description,
        videoUrl: videoUrl || '',
        thumbnailUrl: thumbnailUrl || null,
        r2ObjectKey: r2ObjectKey || null,  // Permanent R2 object key
        provider: resolvedProvider,
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
      update: { assignedLanguageId: languageId, languageSelectionRequired: false },
      create: { userId, assignedLanguageId: languageId, languageSelectionRequired: false },
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
