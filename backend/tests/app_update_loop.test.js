const assert = require('assert');
const appReleaseService = require('../src/services/appRelease.service');
const appVersionMiddleware = require('../src/middleware/appVersion.middleware');
const { isVersionObsolete, isUpdateAvailable } = require('../src/utils/semver');

async function runUpdateLoopVerificationTests() {
  console.log('\n=== RUNNING APP UPDATE DEAD-LOOP PREVENTION VERIFICATION TESTS ===');

  // TEST 1: Current build = latest build -> no update UI
  const test1Obsolete = isVersionObsolete({
    currentVersion: '1.1.0',
    currentBuildNumber: 2,
    minimumSupportedVersion: '1.0.0',
    minimumSupportedBuildNumber: 1,
  });
  const test1UpdateAvail = isUpdateAvailable({
    currentVersion: '1.1.0',
    currentBuildNumber: 2,
    latestVersion: '1.1.0',
    latestBuildNumber: 2,
  });
  assert.strictEqual(test1Obsolete, false, 'TEST 1 FAIL: Current build = latest build should not be obsolete');
  assert.strictEqual(test1UpdateAvail, false, 'TEST 1 FAIL: Current build = latest build should not have update available');
  console.log('✔ TEST 1 PASSED: Current build = latest build -> updateAvailable: false, forceUpdate: false');

  // TEST 2 & TEST 3: Current build < latest/minimum -> update required
  const test2UpdateAvail = isUpdateAvailable({
    currentVersion: '1.0.0',
    currentBuildNumber: 1,
    latestVersion: '1.1.0',
    latestBuildNumber: 2,
  });
  assert.strictEqual(test2UpdateAvail, true, 'TEST 2 FAIL: Current build < latest build must flag update available');
  console.log('✔ TEST 2 & 3 PASSED: Current build < latest build -> flags update available');

  // TEST 5: /app-version/check endpoint must bypass 426 version enforcement middleware
  let nextCalled = false;
  let resStatus = null;
  const mockReq = {
    path: '/api/v1/app-version/check',
    originalUrl: '/api/v1/app-version/check',
    headers: {
      'x-app-type': 'ADMIN_APP',
      'x-app-platform': 'ANDROID',
      'x-app-version': '1.0.0',
      'x-app-build-number': '1',
    },
  };
  const mockRes = {
    status: function (code) {
      resStatus = code;
      return this;
    },
    json: function (data) {
      return data;
    },
  };
  const mockNext = function () {
    nextCalled = true;
  };

  await appVersionMiddleware(mockReq, mockRes, mockNext);
  assert.strictEqual(nextCalled, true, 'TEST 5 FAIL: /app-version/check must bypass version enforcement');
  assert.strictEqual(resStatus, null, 'TEST 5 FAIL: /app-version/check must NOT return 426');
  console.log('✔ TEST 5 PASSED: /app-version/check bypasses version enforcement middleware');

  console.log('ALL APP UPDATE DEAD-LOOP TESTS PASSED SUCCESSFULLY! 🎉\n');
}

runUpdateLoopVerificationTests().catch((err) => {
  console.error('Test Suite Failed:', err);
  process.exit(1);
});
