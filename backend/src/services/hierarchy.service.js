const hierarchyRepository = require('../repositories/hierarchy.repository');
const hierarchyHelper = require('../utils/hierarchyHelper');

class HierarchyService {
  /**
   * Initialize a hierarchy node for a newly registered user
   * @param {string} userId 
   * @param {string|null} parentId - Direct referrer's user ID
   */
  async createNodeForUser(userId, parentId) {
    let path = '';
    let level = 0;

    if (parentId) {
      const parentNode = await hierarchyRepository.findByUserId(parentId);
      if (parentNode) {
        path = hierarchyHelper.buildPath(parentNode.path, userId);
        level = parentNode.level + 1;
      } else {
        // Fallback if parent node does not exist in hierarchy table yet, create it as root node first
        path = hierarchyHelper.buildPath(`/${parentId}`, userId);
        level = 1;
      }
    } else {
      // Root level node
      path = hierarchyHelper.buildPath(null, userId);
      level = 0;
    }

    return hierarchyRepository.createNode({
      userId,
      parentId,
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

    // Build hierarchical tree starting from this user
    return hierarchyHelper.buildTree([userNode, ...descendants], userNode.parentId);
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
