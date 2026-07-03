const assert = require('assert');
const http = require('http');
const app = require('../src/app');
const prisma = require('../src/config/database');

async function runTests() {
  console.log('Running Auth Integration Tests...');
  
  // Start Express server on random port
  const server = http.createServer(app);
  server.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api`;

  const testEmail = `testuser_${Date.now()}@example.com`;
  const testPassword = 'Password123!';
  let jwtToken = '';

  try {
    // Test 1: Health check
    console.log('- Testing health check...');
    const healthRes = await fetch(`http://localhost:${port}/health`);
    assert.strictEqual(healthRes.status, 200);
    const healthJson = await healthRes.json();
    assert.strictEqual(healthJson.status, 'OK');

    // Test 2: Register User
    console.log('- Testing user registration...');
    const registerRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        firstName: 'John',
        lastName: 'Doe',
      }),
    });
    
    assert.strictEqual(registerRes.status, 201);
    const registerJson = await registerRes.json();
    assert.strictEqual(registerJson.success, true);
    assert.strictEqual(registerJson.data.user.email, testEmail);
    assert.ok(registerJson.data.user.referralCode);
    assert.ok(registerJson.data.token);

    // Test 3: Register User with invalid email should fail
    console.log('- Testing invalid registration inputs...');
    const invalidRegRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'invalid-email',
        password: '123',
      }),
    });
    assert.strictEqual(invalidRegRes.status, 400);

    // Test 4: Login User
    console.log('- Testing user login...');
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
      }),
    });
    assert.strictEqual(loginRes.status, 200);
    const loginJson = await loginRes.json();
    assert.strictEqual(loginJson.success, true);
    assert.ok(loginJson.data.token);
    jwtToken = loginJson.data.token;

    // Test 5: Profile retrieval
    console.log('- Testing profile endpoint...');
    const profileRes = await fetch(`${baseUrl}/users/profile`, {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });
    assert.strictEqual(profileRes.status, 200);
    const profileJson = await profileRes.json();
    assert.strictEqual(profileJson.success, true);
    assert.strictEqual(profileJson.data.email, testEmail);

    console.log('✅ Auth tests passed successfully.');
  } catch (err) {
    console.error('❌ Auth tests failed:', err);
    process.exitCode = 1;
  } finally {
    // Clean up created user in DB
    try {
      await prisma.profile.deleteMany({ where: { user: { email: testEmail } } });
      await prisma.hierarchyNode.deleteMany({ where: { user: { email: testEmail } } });
      await prisma.user.deleteMany({ where: { email: testEmail } });
    } catch (e) {
      console.warn('DB cleanup warning in test:', e.message);
    }
    
    server.close();
    await prisma.$disconnect();
  }
}

// Execute tests if file run directly
if (require.main === module) {
  runTests();
}

module.exports = runTests;
