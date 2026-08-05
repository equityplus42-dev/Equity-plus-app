const prisma = require('../config/database');
const videoService = require('./video.service');

class LanguageRequestService {
  /**
   * User submits a new Language Change Request
   */
  async createRequest(userId, requestedLanguageId, reason) {
    if (!requestedLanguageId || !reason) {
      throw new Error('Requested language and reason are required');
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: {
          include: { assignedLanguage: true },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const currentLanguageId = user.profile?.assignedLanguageId;
    if (currentLanguageId && currentLanguageId === requestedLanguageId) {
      throw new Error('The requested language is already your assigned language');
    }

    // Check if user has an existing PENDING request
    const pendingRequest = await prisma.languageChangeRequest.findFirst({
      where: {
        userId,
        status: 'PENDING',
      },
    });

    if (pendingRequest) {
      throw new Error('You already have a pending language change request');
    }

    const requestedLang = await prisma.language.findUnique({
      where: { id: requestedLanguageId },
    });
    if (!requestedLang) {
      throw new Error('Requested language folder not found');
    }

    // Fallback currentLanguageId if null
    let validCurrentLangId = currentLanguageId;
    if (!validCurrentLangId) {
      const defaultLang = await prisma.language.findFirst({ where: { isDefault: true } }) || await prisma.language.findFirst();
      validCurrentLangId = defaultLang.id;
    }

    return prisma.languageChangeRequest.create({
      data: {
        userId,
        currentLanguageId: validCurrentLangId,
        requestedLanguageId,
        reason,
        status: 'PENDING',
      },
      include: {
        currentLanguage: true,
        requestedLanguage: true,
      },
    });
  }

  /**
   * User views their language request history
   */
  async getUserRequests(userId) {
    return prisma.languageChangeRequest.findMany({
      where: { userId },
      orderBy: { requestedAt: 'desc' },
      include: {
        currentLanguage: true,
        requestedLanguage: true,
      },
    });
  }

  /**
   * Admin views all language change requests
   */
  async getAdminRequests(status) {
    const where = {};
    if (status && status !== 'ALL') {
      where.status = status;
    }

    return prisma.languageChangeRequest.findMany({
      where,
      orderBy: { requestedAt: 'desc' },
      include: {
        user: {
          include: { profile: true },
        },
        currentLanguage: true,
        requestedLanguage: true,
      },
    });
  }

  /**
   * Admin reviews (Approve/Reject) a language change request
   */
  async reviewRequest(requestId, adminId, status, adminRemarks, resetProgressOption) {
    const reqRecord = await prisma.languageChangeRequest.findUnique({
      where: { id: requestId },
      include: { user: true },
    });

    if (!reqRecord) {
      throw new Error('Language change request not found');
    }

    if (reqRecord.status !== 'PENDING') {
      throw new Error('Request has already been reviewed');
    }

    if (!['APPROVED', 'REJECTED'].includes(status)) {
      throw new Error('Invalid review status. Must be APPROVED or REJECTED');
    }

    const now = new Date();

    if (status === 'APPROVED') {
      // Update user's preferred language
      await prisma.profile.updateMany({
        where: { userId: reqRecord.userId },
        data: { assignedLanguageId: reqRecord.requestedLanguageId },
      });

      // OPTION B: Reset snapshot and video progress if requested
      if (resetProgressOption === 'OPTION_B' || resetProgressOption === true) {
        await videoService.resetUserVideoProgress(reqRecord.userId);
      }
    }

    return prisma.languageChangeRequest.update({
      where: { id: requestId },
      data: {
        status,
        adminRemarks: adminRemarks || null,
        reviewedAt: now,
        reviewedBy: adminId,
      },
      include: {
        currentLanguage: true,
        requestedLanguage: true,
      },
    });
  }
}

module.exports = new LanguageRequestService();
