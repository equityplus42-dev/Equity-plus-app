const assert = require('assert');
const authService = require('../src/services/auth.service');
const developerMiddleware = require('../src/middleware/developer.middleware');
const adminMiddleware = require('../src/middleware/admin.middleware');
const { ROLES } = require('../src/config/constants');
const prisma = require('../src/config/database');

async function runDeveloperRoleTests() {
  console.log('🧪 Testing Developer Role Security & Access Control System...');

  try {
    // 1. Verify Developer User in DB
    const devUser = await prisma.user.findUnique({
      where: { email: 'developer@vridhi.com' },
    });

    assert.ok(devUser, 'Developer user account should exist in database');
    assert.strictEqual(devUser.role, ROLES.DEVELOPER, 'User role must be DEVELOPER');

    // 2. Test Login as Developer
    const loginResult = await authService.login({
      email: 'developer@vridhi.com',
      password: process.env.DEVELOPER_PASSWORD || 'Vr!dhiDev@2026',
    });

    assert.ok(loginResult.token, 'Token should be issued on developer login');
    assert.strictEqual(loginResult.user.role, ROLES.DEVELOPER, 'Returned user role must be DEVELOPER');

    // 3. Test Developer Middleware with DEVELOPER role
    let devPassed = false;
    const reqDev = { user: { id: devUser.id, role: ROLES.DEVELOPER } };
    const resDev = {};
    const nextDev = () => { devPassed = true; };

    developerMiddleware(reqDev, resDev, nextDev);
    assert.strictEqual(devPassed, true, 'developerMiddleware should allow DEVELOPER role');

    // 4. Test Developer Middleware with ADMIN role (Should be blocked)
    let adminBlocked = false;
    const reqAdmin = { user: { id: 'admin-id', role: ROLES.ADMIN } };
    const resAdmin = {
      status(code) {
        if (code === 403) adminBlocked = true;
        return this;
      },
      json(data) {
        return this;
      }
    };
    const nextAdmin = () => {};

    developerMiddleware(reqAdmin, resAdmin, nextAdmin);
    assert.strictEqual(adminBlocked, true, 'developerMiddleware MUST block ADMIN role with 403');

    // 5. Test Developer Middleware with USER role (Should be blocked)
    let userBlocked = false;
    const reqUser = { user: { id: 'user-id', role: ROLES.USER } };
    const resUser = {
      status(code) {
        if (code === 403) userBlocked = true;
        return this;
      },
      json(data) {
        return this;
      }
    };
    const nextUser = () => {};

    developerMiddleware(reqUser, resUser, nextUser);
    assert.strictEqual(userBlocked, true, 'developerMiddleware MUST block USER role with 403');

    // 6. Test Admin Middleware (Should allow DEVELOPER and ADMIN)
    let adminMwPassedDev = false;
    adminMiddleware(reqDev, resDev, () => { adminMwPassedDev = true; });
    assert.strictEqual(adminMwPassedDev, true, 'adminMiddleware should allow DEVELOPER role for admin system maintenance');

    console.log('🎉 ALL DEVELOPER ROLE SECURITY TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('❌ Developer role security tests failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

runDeveloperRoleTests();
