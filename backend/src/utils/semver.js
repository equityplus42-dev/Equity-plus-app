/**
 * Semantic Versioning & Build Number Comparison Utility
 */

/**
 * Parse a semantic version string (e.g. "1.2.3", "v1.10.0") into numeric components.
 * Returns [major, minor, patch] array of numbers, or [0, 0, 0] if invalid.
 */
function parseVersion(v) {
  if (!v || typeof v !== 'string') return [0, 0, 0];
  const cleaned = v.trim().replace(/^v/i, '').split('-')[0];
  const parts = cleaned.split('.').map(p => {
    const num = parseInt(p, 10);
    return isNaN(num) ? 0 : num;
  });
  while (parts.length < 3) {
    parts.push(0);
  }
  return parts.slice(0, 3);
}

/**
 * Compare two semver strings v1 and v2.
 * Returns:
 *   -1 if v1 < v2
 *    0 if v1 === v2
 *    1 if v1 > v2
 */
function compareVersions(v1, v2) {
  const [maj1, min1, pat1] = parseVersion(v1);
  const [maj2, min2, pat2] = parseVersion(v2);

  if (maj1 !== maj2) return maj1 < maj2 ? -1 : 1;
  if (min1 !== min2) return min1 < min2 ? -1 : 1;
  if (pat1 !== pat2) return pat1 < pat2 ? -1 : 1;
  return 0;
}

/**
 * Check if installed version/build is obsolete compared to minimum supported thresholds.
 */
function isVersionObsolete({
  currentVersion,
  currentBuildNumber = 0,
  minimumSupportedVersion,
  minimumSupportedBuildNumber = null,
}) {
  if (!minimumSupportedVersion) return false;

  const cmp = compareVersions(currentVersion, minimumSupportedVersion);
  if (cmp < 0) return true;
  if (cmp === 0 && minimumSupportedBuildNumber !== null && minimumSupportedBuildNumber !== undefined) {
    const currentBuild = parseInt(currentBuildNumber, 10) || 0;
    const minBuild = parseInt(minimumSupportedBuildNumber, 10) || 0;
    if (currentBuild < minBuild) return true;
  }
  return false;
}

/**
 * Check if a newer version/build is available.
 */
function isUpdateAvailable({
  currentVersion,
  currentBuildNumber = 0,
  latestVersion,
  latestBuildNumber = null,
}) {
  if (!latestVersion) return false;

  const cmp = compareVersions(currentVersion, latestVersion);
  if (cmp < 0) return true;
  if (cmp === 0 && latestBuildNumber !== null && latestBuildNumber !== undefined) {
    const currentBuild = parseInt(currentBuildNumber, 10) || 0;
    const latBuild = parseInt(latestBuildNumber, 10) || 0;
    if (currentBuild < latBuild) return true;
  }
  return false;
}

module.exports = {
  parseVersion,
  compareVersions,
  isVersionObsolete,
  isUpdateAvailable,
};
