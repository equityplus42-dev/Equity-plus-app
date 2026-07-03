const assert = require('assert');
const http = require('http');
const app = require('../src/app');
const prisma = require('../src/config/database');

async function runTests() {
  console.log('Running User & Profile Integration Tests...');

  const server = http.createServer(app);
  server.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api`;

  const time = Date.now();
  const testEmail = `userprofile_${time}@example.com`;
  const testPassword = 'Password123!';
  
  let user;
  let token;

  try {
    // 1. Register User
    console.log('- Registering user...');
    const registerRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        firstName: 'OldFirst',
        lastName: 'OldLast',
      }),
    });
    assert.strictEqual(registerRes.status, 201);
    const registerJson = await registerRes.json();
    user = registerJson.data.user;
    token = registerJson.data.token;

    // 2. Update Profile
    console.log('- Testing profile updates...');
    const updateRes = await fetch(`${baseUrl}/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        firstName: 'NewFirst',
        lastName: 'NewLast',
        phoneNumber: '+987654321',
        bio: 'This is my new test biography.'
      }),
    });
    
    assert.strictEqual(updateRes.status, 200);
    const updateJson = await updateRes.json();
    assert.strictEqual(updateJson.success, true);
    assert.strictEqual(updateJson.data.firstName, 'NewFirst');
    assert.strictEqual(updateJson.data.lastName, 'NewLast');
    assert.strictEqual(updateJson.data.phoneNumber, '+987654321');
    assert.strictEqual(updateJson.data.bio, 'This is my new test biography.');

    // 3. Confirm profile update has saved in database
    console.log('- Verifying updates persist in database...');
    const dbProfile = await prisma.profile.findUnique({
      where: { userId: user.id }
    });
    assert.strictEqual(dbProfile.firstName, 'NewFirst');
    assert.strictEqual(dbProfile.lastName, 'NewLast');
    assert.strictEqual(dbProfile.phoneNumber, '+987654321');

    console.log('✅ User and Profile tests passed successfully.');
  } catch (err) {
    console.error('❌ User and Profile tests failed:', err);
    process.exitCode = 1;
  } finally {
    // Cleanup
    try {
      await prisma.profile.deleteMany({ where: { userId: user.id } });
      await prisma.hierarchyNode.deleteMany({ where: { userId: user.id } });
      await prisma.user.deleteMany({ where: { id: user.id } });
    } catch (e) {
      console.warn('DB cleanup warning in test:', e.message);
    }

    server.close();
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  runTests();
}

module.exports = runTests;
