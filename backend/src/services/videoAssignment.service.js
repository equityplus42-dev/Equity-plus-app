const prisma = require('../config/database');
const auditLogService = require('./auditLog.service');

class VideoAssignmentService {
  /**
   * Get assignment overview summary stats for Admin Dashboard
   */
  async getAssignmentDashboardStats() {
    const [totalVideos, snapshotVideoRecords, totalAssignments, usersWithAccess] = await Promise.all([
      prisma.video.count({ where: { isActive: true } }),
      prisma.snapshotVideo.findMany({
        distinct: ['videoId'],
        select: { videoId: true },
      }),
      prisma.videoAssignment.count({ where: { status: 'ACTIVE' } }),
      prisma.videoAssignment.groupBy({
        by: ['userId'],
        where: { status: 'ACTIVE' },
      }),
    ]);

    const snapshotVideoIds = snapshotVideoRecords.map((sv) => sv.videoId);

    // Assigned videos = videos with active direct assignment OR used in any user snapshot
    const assignedVideos = await prisma.video.count({
      where: {
        isActive: true,
        OR: [
          { assignments: { some: { status: 'ACTIVE' } } },
          { id: { in: snapshotVideoIds } },
        ],
      },
    });

    // Unassigned videos: Active videos that have neither current assignments nor snapshot records
    const unassignedVideos = await prisma.video.count({
      where: {
        isActive: true,
        id: { notIn: snapshotVideoIds },
        assignments: { none: { status: 'ACTIVE' } },
      },
    });

    return {
      totalVideos,
      assignedVideos,
      unassignedVideos,
      activeAssignments: totalAssignments,
      usersWithAccess: usersWithAccess.length,
      snapshotProtectedVideosCount: snapshotVideoIds.length,
    };
  }

  /**
   * List videos with assignment status & count metrics for Admin Video Assignments Screen
   */
  async getVideoAssignments({ languageId, productId, search, page = 1, limit = 20 }) {
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const take = parseInt(limit, 10);

    const where = { isActive: true };
    if (languageId) where.languageId = languageId;
    if (productId) where.productId = productId;
    if (search && search.trim()) {
      where.OR = [
        { title: { contains: search.trim(), mode: 'insensitive' } },
        { description: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }

    const [total, videos] = await Promise.all([
      prisma.video.count({ where }),
      prisma.video.findMany({
        where,
        skip,
        take,
        orderBy: [{ orderIndex: 'asc' }, { createdAt: 'desc' }],
        include: {
          language: true,
          product: true,
          _count: {
            select: {
              assignments: { where: { status: 'ACTIVE' } },
              snapshotVideos: true,
            },
          },
        },
      }),
    ]);

    const items = videos.map((v) => {
      const activeAccessCount = v._count.assignments;
      // snapshotUserCount: each SnapshotVideo row belongs to a distinct user snapshot → 1 row per user
      const snapshotUserCount = v._count.snapshotVideos;
      const isSnapshotProtected = snapshotUserCount > 0;

      let assignmentStatus = 'UNASSIGNED';
      let assignmentLabel = 'Unassigned';

      if (isSnapshotProtected) {
        assignmentStatus = 'LOCKED_BY_SNAPSHOT';
        assignmentLabel = 'Used in User Snapshots — Deletion Protected';
      } else if (activeAccessCount > 0) {
        assignmentStatus = 'ASSIGNED';
        assignmentLabel = 'Active User Assignment';
      }

      return {
        id: v.id,
        title: v.title,
        description: v.description,
        videoUrl: v.videoUrl,
        thumbnailUrl: v.thumbnailUrl,
        duration: v.duration,
        languageId: v.languageId,
        languageName: v.language.name,
        productId: v.productId,
        productName: v.product?.name || null,
        status: v.status,
        orderIndex: v.orderIndex,
        activeAccessCount,
        snapshotUserCount,
        isSnapshotProtected,
        assignmentStatus,
        assignmentLabel,
        createdAt: v.createdAt,
      };
    });

    return {
      total,
      page: parseInt(page, 10),
      limit: take,
      totalPages: Math.ceil(total / take),
      items,
    };
  }

  /**
   * Detailed breakdown for a single video showing user assignments & snapshot categorization
   */
  async getVideoAssignmentDetails(videoId, { search, page = 1, limit = 20 }) {
    const video = await prisma.video.findUnique({
      where: { id: videoId },
      include: { language: true, product: true },
    });

    if (!video) {
      const err = new Error('Video not found');
      err.statusCode = 404;
      throw err;
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const take = parseInt(limit, 10);

    const userWhere = { role: 'USER', isApproved: true, isDeleted: false, isTestUser: false };
    if (search && search.trim()) {
      userWhere.OR = [
        { email: { contains: search.trim(), mode: 'insensitive' } },
        { profile: { firstName: { contains: search.trim(), mode: 'insensitive' } } },
        { profile: { lastName: { contains: search.trim(), mode: 'insensitive' } } },
        { profile: { phoneNumber: { contains: search.trim(), mode: 'insensitive' } } },
      ];
    }

    // Get active assignments for this video
    const activeAssignments = await prisma.videoAssignment.findMany({
      where: { videoId, status: 'ACTIVE' },
      include: {
        user: {
          include: {
            profile: { include: { assignedLanguage: true, assignedProduct: true } },
          },
        },
      },
    });

    // Get snapshot records for this video
    const snapshotRecords = await prisma.snapshotVideo.findMany({
      where: { videoId },
      include: {
        snapshot: {
          include: {
            user: {
              include: {
                profile: { include: { assignedLanguage: true, assignedProduct: true } },
              },
            },
          },
        },
      },
    });

    // Get progress records for this video
    const progressRecords = await prisma.userVideoProgress.findMany({
      where: { videoId },
    });
    const progressMap = new Map(progressRecords.map((pr) => [pr.userId, pr]));

    const assignedUserIds = new Set(activeAssignments.map((a) => a.userId));
    const snapshotUserIds = new Set(snapshotRecords.map((sr) => sr.snapshot.userId));

    const totalAssignedUsers = activeAssignments.length;
    const totalSnapshotUsers = snapshotRecords.length;

    // Users with active assignments
    const assignedUsers = activeAssignments.map((a) => {
      const pr = progressMap.get(a.userId);
      return {
        userId: a.user.id,
        email: a.user.email,
        firstName: a.user.profile?.firstName || '',
        lastName: a.user.profile?.lastName || '',
        phoneNumber: a.user.profile?.phoneNumber || '',
        languageName: a.user.profile?.assignedLanguage?.name || 'Unassigned',
        productName: a.user.profile?.assignedProduct?.name || 'None',
        assignedAt: a.assignedAt,
        status: a.status,
        inSnapshot: snapshotUserIds.has(a.userId),
        watchedSecs: pr ? pr.watchedSecs : 0,
        isCompleted: pr ? pr.isCompleted : false,
        lastWatched: pr ? pr.lastWatched : null,
      };
    });

    return {
      video: {
        id: video.id,
        title: video.title,
        description: video.description,
        duration: video.duration,
        languageName: video.language.name,
        productName: video.product?.name || null,
        status: video.status,
        createdAt: video.createdAt,
      },
      summary: {
        totalAssignedUsers,
        totalSnapshotUsers,
        isSnapshotProtected: totalSnapshotUsers > 0,
      },
      assignedUsers,
    };
  }

  /**
   * Assign video to a user (Validates user, approval, product access, language match, video active)
   */
  async assignVideoToUser({ userId, videoId, adminId, reqIp, userAgent }) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, productAccesses: true },
    });

    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 404;
      throw err;
    }

    if (!user.isApproved || !user.isActive || user.isDeleted) {
      const err = new Error('Cannot assign video to inactive or unapproved user');
      err.statusCode = 400;
      throw err;
    }

    const video = await prisma.video.findUnique({
      where: { id: videoId },
      include: { language: true, product: true },
    });

    if (!video || !video.isActive) {
      const err = new Error('Video not found or inactive');
      err.statusCode = 404;
      throw err;
    }

    // Language match validation
    if (user.profile?.assignedLanguageId && user.profile.assignedLanguageId !== video.languageId) {
      const err = new Error(`User's assigned language does not match video language (${video.language.name})`);
      err.statusCode = 400;
      throw err;
    }

    // Product access validation (If product is specified on video)
    if (video.productId) {
      const activeProductAccess = user.productAccesses.some(
        (pa) => pa.productId === video.productId && pa.status === 'ACTIVE'
      );
      if (!activeProductAccess) {
        const err = new Error(`User does not have an ACTIVE access pass for product "${video.product?.name}"`);
        err.statusCode = 400;
        throw err;
      }
    }

    const assignment = await prisma.videoAssignment.upsert({
      where: {
        userId_videoId: { userId, videoId },
      },
      update: {
        status: 'ACTIVE',
        assignedAt: new Date(),
        assignedBy: adminId || 'ADMIN',
        productId: video.productId,
        languageId: video.languageId,
      },
      create: {
        userId,
        videoId,
        productId: video.productId,
        languageId: video.languageId,
        status: 'ACTIVE',
        assignedBy: adminId || 'ADMIN',
      },
    });

    await auditLogService.log(
      { ip: reqIp, headers: { 'user-agent': userAgent } },
      'VIDEO_ASSIGNED',
      adminId,
      JSON.stringify({ targetUserId: userId, videoId, videoTitle: video.title })
    );

    return assignment;
  }

  /**
   * Bulk assign video to multiple users
   */
  async bulkAssignVideo({ videoId, userIds, adminId, reqIp, userAgent }) {
    if (!Array.isArray(userIds) || userIds.length === 0) {
      const err = new Error('userIds array is required');
      err.statusCode = 400;
      throw err;
    }

    let assignedCount = 0;
    const errors = [];

    for (const uId of userIds) {
      try {
        await this.assignVideoToUser({ userId: uId, videoId, adminId, reqIp, userAgent });
        assignedCount++;
      } catch (e) {
        errors.push({ userId: uId, message: e.message });
      }
    }

    await auditLogService.log(
      { ip: reqIp, headers: { 'user-agent': userAgent } },
      'VIDEO_BULK_ASSIGNED',
      adminId,
      JSON.stringify({ videoId, totalTargetUsers: userIds.length, assignedCount, errorCount: errors.length })
    );

    return {
      success: true,
      totalRequested: userIds.length,
      assignedCount,
      errors,
    };
  }

  /**
   * Unassign video from user (Preserves historical SnapshotVideo)
   */
  async unassignVideoFromUser({ userId, videoId, adminId, reqIp, userAgent }) {
    const assignment = await prisma.videoAssignment.findUnique({
      where: { userId_videoId: { userId, videoId } },
    });

    // Check if video is part of user's historical snapshot
    const userSnapshot = await prisma.userVideoSnapshot.findUnique({
      where: { userId },
      include: { snapshotVideos: true },
    });

    const isHistoricalSnapshotMember = userSnapshot?.snapshotVideos.some((sv) => sv.videoId === videoId);

    if (assignment) {
      await prisma.videoAssignment.update({
        where: { id: assignment.id },
        data: {
          status: 'REVOKED',
          unassignedAt: new Date(),
          unassignedBy: adminId || 'ADMIN',
        },
      });
    }

    await auditLogService.log(
      { ip: reqIp, headers: { 'user-agent': userAgent } },
      isHistoricalSnapshotMember ? 'VIDEO_UNASSIGN_BLOCKED' : 'VIDEO_UNASSIGNED',
      adminId,
      JSON.stringify({
        targetUserId: userId,
        videoId,
        historicalSnapshotProtected: isHistoricalSnapshotMember,
      })
    );

    return {
      success: true,
      message: isHistoricalSnapshotMember
        ? 'Current video assignment revoked. Historical snapshot record preserved.'
        : 'Video unassigned successfully.',
      historicalSnapshotProtected: isHistoricalSnapshotMember,
    };
  }

  /**
   * Bulk unassign video
   */
  async bulkUnassignVideo({ videoId, userIds, adminId, reqIp, userAgent }) {
    if (!Array.isArray(userIds) || userIds.length === 0) {
      const err = new Error('userIds array is required');
      err.statusCode = 400;
      throw err;
    }

    let unassignedCount = 0;
    let protectedSnapshotCount = 0;

    for (const uId of userIds) {
      const res = await this.unassignVideoFromUser({ userId: uId, videoId, adminId, reqIp, userAgent });
      if (res.success) unassignedCount++;
      if (res.historicalSnapshotProtected) protectedSnapshotCount++;
    }

    await auditLogService.log(
      { ip: reqIp, headers: { 'user-agent': userAgent } },
      'VIDEO_BULK_UNASSIGNED',
      adminId,
      JSON.stringify({ videoId, totalTargetUsers: userIds.length, unassignedCount, protectedSnapshotCount })
    );

    return {
      success: true,
      totalRequested: userIds.length,
      unassignedCount,
      protectedSnapshotCount,
    };
  }

  /**
   * Detailed User Video Access breakdown for Admin User Directory
   */
  async getUserVideoAssignmentsAdmin(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedLanguage: true, assignedProduct: true },
        },
        productAccesses: { include: { product: true } },
        videoSnapshot: { include: { snapshotVideos: true } },
        videoAssignments: {
          where: { status: 'ACTIVE' },
          include: { video: true },
        },
        videoProgress: true,
      },
    });

    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 404;
      throw err;
    }

    const snapshot = user.videoSnapshot;
    const snapshotVideoIds = snapshot ? snapshot.snapshotVideos.map((sv) => sv.videoId) : [];

    // Historical Snapshot Videos
    const historicalSnapshotVideos = snapshot
      ? await prisma.video.findMany({
          where: { id: { in: snapshotVideoIds } },
          include: { language: true },
        })
      : [];

    // Current Video Assignments
    const currentAssignments = user.videoAssignments.map((va) => ({
      id: va.id,
      videoId: va.video.id,
      title: va.video.title,
      languageId: va.video.languageId,
      status: va.status,
      assignedAt: va.assignedAt,
    }));

    const progressMap = new Map(user.videoProgress.map((p) => [p.videoId, p]));

    return {
      userId: user.id,
      email: user.email,
      assignedLanguage: user.profile?.assignedLanguage || null,
      assignedProduct: user.profile?.assignedProduct || null,
      productAccesses: user.productAccesses,
      snapshotSummary: snapshot
        ? {
            snapshotId: snapshot.id,
            snapshotTakenAt: snapshot.snapshotTakenAt,
            snapshotVideoCount: snapshot.snapshotVideoCount,
            snapshotTotalDurationSeconds: snapshot.snapshotTotalDurationSeconds,
            refundEligible: snapshot.refundEligible,
            newVideosUnlocked: snapshot.newVideosUnlocked,
          }
        : null,
      historicalSnapshotVideos,
      currentAssignments,
    };
  }

  /**
   * Force-delete a video — even if it is snapshot-protected.
   * Removes SnapshotVideo rows, recalculates UserVideoSnapshot counts,
   * revokes all VideoAssignment records, then hard-deletes the Video row.
   *
   * ⚠️ This PERMANENTLY modifies user snapshot denominators.
   * Only call with explicit admin confirmation.
   */
  async forceDeleteVideo({ videoId, adminId, reqIp, userAgent }) {
    const video = await prisma.video.findUnique({
      where: { id: videoId },
      include: { snapshotVideos: true },
    });

    if (!video) {
      const err = new Error('Video not found');
      err.statusCode = 404;
      throw err;
    }

    // Collect affected snapshot IDs (each snapshotVideo row belongs to one UserVideoSnapshot)
    const snapshotIds = [...new Set(video.snapshotVideos.map((sv) => sv.snapshotId))];

    // Remove SnapshotVideo rows for this video
    await prisma.snapshotVideo.deleteMany({ where: { videoId } });

    // Recalculate and update each affected UserVideoSnapshot
    for (const snapshotId of snapshotIds) {
      const remainingVideos = await prisma.snapshotVideo.findMany({
        where: { snapshotId },
      });
      const newCount = remainingVideos.length;
      const newDuration = remainingVideos.reduce((sum, sv) => sum + sv.videoDurationSeconds, 0);

      await prisma.userVideoSnapshot.update({
        where: { id: snapshotId },
        data: {
          snapshotVideoCount: newCount,
          snapshotTotalDurationSeconds: newDuration,
        },
      });
    }

    // Revoke all VideoAssignment records for this video
    await prisma.videoAssignment.updateMany({
      where: { videoId, status: 'ACTIVE' },
      data: { status: 'REVOKED', unassignedAt: new Date(), unassignedBy: adminId || 'ADMIN' },
    });

    // Delete underlying file from Cloudflare R2 bucket or Cloudinary storage
    const isR2Video =
      Boolean(video.r2ObjectKey) ||
      (video.videoUrl && (video.videoUrl.includes('r2.cloudflarestorage.com') || video.videoUrl.includes('.r2.dev')));

    if (isR2Video) {
      try {
        const cloudflareR2Service = require('./cloudflareR2.service');
        // Prefer permanent r2ObjectKey; fall back to extracting from URL for legacy records
        const objectKey = video.r2ObjectKey || cloudflareR2Service.extractR2ObjectKeyFromUrl(video.videoUrl);
        if (objectKey) {
          await cloudflareR2Service.deleteFile(objectKey);
        } else {
          console.warn(`[VideoAssignmentService] Could not determine R2 object key for video ${videoId}. Manual cleanup may be required.`);
        }
      } catch (cloudErr) {
        console.warn(`[VideoAssignmentService] R2 file cleanup notice: ${cloudErr.message}`);
      }
    } else if (video.videoUrl && (video.videoUrl.includes('res.cloudinary.com') || video.videoUrl.includes('cloudinary'))) {
      // Cloudinary cleanup (no-op here — Cloudinary videos are not auto-deleted by default)
      console.info(`[VideoAssignmentService] Cloudinary video ${videoId} removed from DB only. Manual Cloudinary cleanup may be needed.`);
    }

    // Hard-delete the video
    await prisma.video.delete({ where: { id: videoId } });

    await auditLogService.log(
      { ip: reqIp, headers: { 'user-agent': userAgent } },
      'VIDEO_FORCE_DELETED',
      adminId,
      JSON.stringify({
        videoId,
        videoTitle: video.title,
        affectedSnapshotCount: snapshotIds.length,
      })
    );

    return {
      success: true,
      message: `Video "${video.title}" permanently deleted. ${snapshotIds.length} user snapshot(s) updated.`,
      affectedSnapshotCount: snapshotIds.length,
    };
  }
}

module.exports = new VideoAssignmentService();
