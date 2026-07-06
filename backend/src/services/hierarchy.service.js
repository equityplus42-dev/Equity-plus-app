const hierarchyRepository = require('../repositories/hierarchy.repository');
const hierarchyHelper = require('../utils/hierarchyHelper');
const prisma = require('../config/database');

class HierarchyService {
  /**
   * Initialize a hierarchy node for a newly registered user
   * @param {string} userId 
   * @param {string|null} parentId - Direct referrer's user ID
   */
  async createNodeForUser(userId, parentId) {
    let path = '';
    let level = 0;

    // Fetch the user to check their role
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true }
    });

    let effectiveParentId = parentId;

    if (!effectiveParentId && user && user.role !== 'ADMIN') {
      // Direct registration of standard user (without referrer) -> fall back to the first active Admin
      const admin = await prisma.user.findFirst({
        where: { role: 'ADMIN', isDeleted: false },
        orderBy: { createdAt: 'asc' }
      });
      if (admin) {
        effectiveParentId = admin.id;
      }
    }

    if (effectiveParentId) {
      const parentNode = await hierarchyRepository.findByUserId(effectiveParentId);
      if (parentNode) {
        path = hierarchyHelper.buildPath(parentNode.path, userId);
        level = parentNode.level + 1;
      } else {
        // Fallback if parent node does not exist in hierarchy table yet, create it as root node first
        path = hierarchyHelper.buildPath(`/${effectiveParentId}`, userId);
        level = 1;
      }
    } else {
      // Root level node
      path = hierarchyHelper.buildPath(null, userId);
      level = 0;
    }

    return hierarchyRepository.createNode({
      userId,
      parentId: effectiveParentId,
      path,
      level,
    });
  }

  /**
   * Fetch downline tree for a specific user
   * @param {string} userId 
   * @param {number} maxDepth 
   */
  async getUserHierarchy(userId, maxDepth) {
    const userNode = await hierarchyRepository.findByUserId(userId);
    if (!userNode) {
      return [];
    }

    const maxLevel = maxDepth !== undefined ? userNode.level + maxDepth : undefined;
    const descendants = await hierarchyRepository.findDescendants(userNode.path, maxLevel);

    // Map database nodes to relative levels and mask downline members' data for standard users
    const rootLevel = userNode.level;
    const relativeNodes = [userNode, ...descendants].map((node) => {
      const isSelf = node.userId === userId;

      let maskedUser = node.user;
      if (!isSelf && node.user) {
        maskedUser = {
          email: node.user.profile?.phoneNumber || 'N/A',
          referralCode: node.user.referralCode,
          profile: {
            firstName: node.user.profile?.firstName || 'User',
            lastName: node.user.profile?.lastName || '',
            phoneNumber: node.user.profile?.phoneNumber || 'N/A',
            avatarUrl: null,
          }
        };
      }

      return {
        userId: node.userId,
        parentId: node.parentId,
        level: node.level - rootLevel,
        path: node.path,
        user: maskedUser,
      };
    });

    // Build hierarchical tree starting from this user
    return hierarchyHelper.buildTree(relativeNodes, userNode.parentId);
  }

  /**
   * Fetch the global system-wide hierarchy (Admin view)
   */
  async getGlobalHierarchy() {
    const allNodes = await hierarchyRepository.findAllNodes();
    return hierarchyHelper.buildTree(allNodes, null);
  }
}

module.exports = new HierarchyService();
