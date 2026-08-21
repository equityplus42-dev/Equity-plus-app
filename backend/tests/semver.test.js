const assert = require('assert');
const { compareVersions, isVersionObsolete, isUpdateAvailable, parseVersion } = require('../src/utils/semver');

function runSemverTests() {
  console.log('🧪 Testing Semver & Build Number Utility...');

  // 1. Parsing
  assert.deepStrictEqual(parseVersion('1.2.3'), [1, 2, 3]);
  assert.deepStrictEqual(parseVersion('v1.10.0'), [1, 10, 0]);
  assert.deepStrictEqual(parseVersion('2.0.0-beta.1'), [2, 0, 0]);
  assert.deepStrictEqual(parseVersion('1.0'), [1, 0, 0]);

  // 2. Comparison
  assert.strictEqual(compareVersions('1.10.0', '1.9.0'), 1);
  assert.strictEqual(compareVersions('1.9.0', '1.10.0'), -1);
  assert.strictEqual(compareVersions('2.0.0', '1.99.99'), 1);
  assert.strictEqual(compareVersions('1.0.10', '1.0.9'), 1);
  assert.strictEqual(compareVersions('1.0.0', '1.0.0'), 0);

  // 3. Obsolete Checks
  assert.strictEqual(isVersionObsolete({
    currentVersion: '1.0.0',
    currentBuildNumber: 1,
    minimumSupportedVersion: '1.1.0',
    minimumSupportedBuildNumber: 10,
  }), true);

  assert.strictEqual(isVersionObsolete({
    currentVersion: '1.1.0',
    currentBuildNumber: 5,
    minimumSupportedVersion: '1.1.0',
    minimumSupportedBuildNumber: 10,
  }), true);

  assert.strictEqual(isVersionObsolete({
    currentVersion: '1.1.0',
    currentBuildNumber: 10,
    minimumSupportedVersion: '1.1.0',
    minimumSupportedBuildNumber: 10,
  }), false);

  assert.strictEqual(isVersionObsolete({
    currentVersion: '1.2.0',
    currentBuildNumber: 1,
    minimumSupportedVersion: '1.1.0',
    minimumSupportedBuildNumber: 10,
  }), false);

  // 4. Update Available Checks
  assert.strictEqual(isUpdateAvailable({
    currentVersion: '1.0.0',
    currentBuildNumber: 1,
    latestVersion: '1.1.0',
    latestBuildNumber: 10,
  }), true);

  assert.strictEqual(isUpdateAvailable({
    currentVersion: '1.1.0',
    currentBuildNumber: 5,
    latestVersion: '1.1.0',
    latestBuildNumber: 10,
  }), true);

  assert.strictEqual(isUpdateAvailable({
    currentVersion: '1.1.0',
    currentBuildNumber: 10,
    latestVersion: '1.1.0',
    latestBuildNumber: 10,
  }), false);

  console.log('✅ All Semver & Build Number tests passed successfully!');
}

runSemverTests();
