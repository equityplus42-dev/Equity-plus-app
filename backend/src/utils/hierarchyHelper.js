/**
 * Helper utilities for working with materialized path referral hierarchies
 */

/**
 * Build the hierarchical path for a user
 * @param {string|null} parentPath 
 * @param {string} userId 
 * @returns {string}
 */
function buildPath(parentPath, userId) {
  if (!parentPath) {
    return `/${userId}`;
  }
  // Ensure we don't end up with double slashes
  const cleanParent = parentPath.endsWith('/') ? parentPath.slice(0, -1) : parentPath;
  return `${cleanParent}/${userId}`;
}

/**
 * Get all ancestor IDs from a materialized path (excluding the user's own ID)
 * @param {string} path - Materialized path, e.g. "/id1/id2/id3"
 * @returns {string[]} - Array of ancestor IDs in order from root downwards, e.g. ["id1", "id2"]
 */
function getAncestorsFromPath(path) {
  if (!path || path === '/') return [];
  const parts = path.split('/').filter(p => p !== '');
  // Remove the last part which is the user themselves
  parts.pop();
  return parts;
}

/**
 * Construct a nested tree from a flat list of nodes
 * @param {Array} nodes - List of nodes, each having { userId, parentId, user: { email, profile: { firstName, lastName, avatarUrl } } }
 * @param {string|null} rootId - The root node ID
 * @returns {Array} - Nested tree structures
 */
function buildTree(nodes, rootId = null) {
  const nodeMap = {};
  
  // Initialize map and children arrays
  nodes.forEach(node => {
    nodeMap[node.userId] = {
      id: node.userId,
      parentId: node.parentId,
      email: node.user?.email || '',
      name: node.user?.profile 
        ? `${node.user.profile.firstName || ''} ${node.user.profile.lastName || ''}`.trim() 
        : 'User',
      avatarUrl: node.user?.profile?.avatarUrl || null,
      level: node.level,
      path: node.path,
      referralCode: node.user?.referralCode || '',
      phoneNumber: node.user?.profile?.phoneNumber || '',
      panNumber: node.user?.profile?.panNumber || '',
      aadharNumber: node.user?.profile?.aadharNumber || '',
      whatsApp: node.user?.profile?.whatsApp || '',
      state: node.user?.profile?.state || '',
      district: node.user?.profile?.district || '',
      points: node.user?.points || 0,
      children: []
    };
  });
  
  const rootNodes = [];
  
  nodes.forEach(node => {
    const mappedNode = nodeMap[node.userId];
    let parentId = node.parentId;

    // Reparent if direct parent is deleted/missing from tree nodes list
    if (parentId && !nodeMap[parentId] && node.path) {
      const pathParts = node.path.split('/').filter(p => p !== '');
      const currentIndex = pathParts.indexOf(node.userId);
      if (currentIndex > 0) {
        for (let i = currentIndex - 1; i >= 0; i--) {
          const ancestorId = pathParts[i];
          if (nodeMap[ancestorId]) {
            parentId = ancestorId;
            mappedNode.parentId = parentId;
            break;
          }
        }
      }
    }
    
    if (!parentId || parentId === rootId || !nodeMap[parentId]) {
      // If no parent or parent is outside our list, it's a root node in our tree context
      rootNodes.push(mappedNode);
    } else {
      // Add as child to the parent
      nodeMap[parentId].children.push(mappedNode);
    }
  });
  
  return rootNodes;
}

module.exports = {
  buildPath,
  getAncestorsFromPath,
  buildTree,
};
