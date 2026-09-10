const assert = require('assert');
const http = require('http');
const app = require('../src/app');
const prisma = require('../src/config/database');

async function runTests() {
  console.log('Running Passkey & WebAuthn Integration Tests...');

  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  const testEmail = `passkey_user_${Date.now()}@example.com`;
  const testPassword = 'SecurePassword123!';
  let jwtToken = '';
  let testUserId = '';

  try {
    // 1. Digital Asset Links test
    console.log('- Test 1: Testing /.well-known/assetlinks.json...');
    const assetlinksRes = await fetch(`http://localhost:${port}/.well-known/assetlinks.json`);
    assert.strictEqual(assetlinksRes.status, 200);
    assert.ok(assetlinksRes.headers.get('content-type').includes('application/json'));
    const assetlinks = await assetlinksRes.json();
    assert.ok(Array.isArray(assetlinks));
    assert.strictEqual(assetlinks[0].target.package_name, 'com.referral.user_app');
    assert.ok(assetlinks[0].relation.includes('delegate_permission/common.get_login_creds'));
    assert.ok(assetlinks[0].target.sha256_cert_fingerprints.includes('6D:AF:54:6C:9E:AC:C0:49:C6:DA:31:AC:B1:3C:50:AB:7A:8F:7E:FF:46:8C:FC:03:3A:61:34:B7:DB:97:4C:2B'));

    // 2. Setup user for passkey testing
    console.log('- Test 2: Registering test user...');
    const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    const refCode = admin ? admin.referralCode : 'ADMINREF';
    let lang = await prisma.language.findFirst();
    if (!lang) {
      lang = await prisma.language.create({ data: { name: 'English', code: 'en' } });
    }

    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        firstName: 'Passkey',
        lastName: 'Tester',
        referralCode: refCode,
        preferredLanguageId: lang.id,
      }),
    });
    assert.strictEqual(regRes.status, 201);
    const regJson = await regRes.json();
    jwtToken = regJson.data.token;
    testUserId = regJson.data.user.id;
    assert.ok(jwtToken, 'User must receive JWT on auto-approval');

    // 3. Public login options test (discoverable / usernameless challenge)
    console.log('- Test 3: Testing public login options generation (usernameless)...');
    const loginOptsRes = await fetch(`${baseUrl}/auth/passkey/login/options`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    assert.strictEqual(loginOptsRes.status, 200);
    const loginOptsJson = await loginOptsRes.json();
    assert.strictEqual(loginOptsJson.success, true);
    assert.ok(loginOptsJson.data.challenge);
    assert.strictEqual(typeof loginOptsJson.data.challenge, 'string');

    // Verify challenge was saved to WebAuthnChallenge table
    const storedAuthChallenge = await prisma.webAuthnChallenge.findUnique({
      where: { challenge: loginOptsJson.data.challenge },
    });
    assert.ok(storedAuthChallenge);
    assert.strictEqual(storedAuthChallenge.type, 'AUTHENTICATION');

    // 4. Registration options without auth must return 401
    console.log('- Test 4: Testing registration options without auth (must fail with 401)...');
    const unauthRegOptsRes = await fetch(`${baseUrl}/auth/passkey/register/options`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });
    assert.strictEqual(unauthRegOptsRes.status, 401);

    // 5. Registration options with valid auth
    console.log('- Test 5: Testing registration options with valid auth...');
    const authRegOptsRes = await fetch(`${baseUrl}/auth/passkey/register/options`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${jwtToken}`,
      },
    });
    assert.strictEqual(authRegOptsRes.status, 200);
    const authRegOptsJson = await authRegOptsRes.json();
    assert.strictEqual(authRegOptsJson.success, true);
    assert.ok(authRegOptsJson.data.challenge);
    assert.strictEqual(authRegOptsJson.data.user.name, testEmail);

    // Verify challenge was saved to WebAuthnChallenge table
    const storedRegChallenge = await prisma.webAuthnChallenge.findUnique({
      where: { challenge: authRegOptsJson.data.challenge },
    });
    assert.ok(storedRegChallenge);
    assert.strictEqual(storedRegChallenge.type, 'REGISTRATION');
    assert.strictEqual(storedRegChallenge.userId, testUserId);

    // 6. Registration verification with invalid response must return 400
    console.log('- Test 6: Testing registration verification with invalid response...');
    const invalidVerifyRes = await fetch(`${baseUrl}/auth/passkey/register/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${jwtToken}`,
      },
      body: JSON.stringify({
        name: 'My Android Phone',
        response: {
          id: 'invalid-cred-id',
          rawId: 'invalid-raw-id',
          response: {
            clientDataJSON: Buffer.from(JSON.stringify({ challenge: 'fake-challenge', type: 'webauthn.create' })).toString('base64url'),
            attestationObject: 'fake-attestation',
          },
          type: 'public-key',
        },
      }),
    });
    assert.strictEqual(invalidVerifyRes.status, 400);

    // 7. Login verify with non-existent credential must return 401
    console.log('- Test 7: Testing login verification with unrecognized credential...');
    const nonExistentLoginRes = await fetch(`${baseUrl}/auth/passkey/login/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        response: {
          id: 'non-existent-credential-id',
          response: {
            clientDataJSON: Buffer.from(JSON.stringify({ challenge: 'test', type: 'webauthn.get' })).toString('base64url'),
          },
        },
      }),
    });
    assert.strictEqual(nonExistentLoginRes.status, 401);

    // 8. List passkeys endpoint
    console.log('- Test 8: Testing credentials list endpoint...');
    const listRes = await fetch(`${baseUrl}/auth/passkey/credentials`, {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });
    assert.strictEqual(listRes.status, 200);
    const listJson = await listRes.json();
    assert.strictEqual(listJson.success, true);
    assert.ok(Array.isArray(listJson.data));
    assert.strictEqual(listJson.data.length, 0); // User has no passkeys yet

    // 9. Create a mock PasskeyCredential directly in database to test retrieval and lockout safety
    console.log('- Test 9: Testing credential management and deletion safety...');
    const mockCred = await prisma.passkeyCredential.create({
      data: {
        userId: testUserId,
        credentialId: `test-credential-${Date.now()}`,
        publicKey: Buffer.from('mock-public-key').toString('base64url'),
        counter: 0,
        name: 'Test Device Passkey',
      },
    });

    const listWithCredRes = await fetch(`${baseUrl}/auth/passkey/credentials`, {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });
    const listWithCredJson = await listWithCredRes.json();
    assert.strictEqual(listWithCredJson.data.length, 1);
    assert.strictEqual(listWithCredJson.data[0].id, mockCred.id);
    assert.strictEqual(listWithCredJson.data[0].name, 'Test Device Passkey');

    // Test rename
    const renameRes = await fetch(`${baseUrl}/auth/passkey/credentials/${mockCred.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${jwtToken}`,
      },
      body: JSON.stringify({ name: 'Work Laptop' }),
    });
    assert.strictEqual(renameRes.status, 200);
    const renameJson = await renameRes.json();
    assert.strictEqual(renameJson.data.name, 'Work Laptop');

    // Test deletion (user has a password, so deletion of their only passkey is permitted)
    const deleteRes = await fetch(`${baseUrl}/auth/passkey/credentials/${mockCred.id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${jwtToken}` },
    });
    assert.strictEqual(deleteRes.status, 200);

    // Verify deletion in database
    const checkDeleted = await prisma.passkeyCredential.findUnique({ where: { id: mockCred.id } });
    assert.strictEqual(checkDeleted, null);

    console.log('✅ All Passkey Integration Tests Passed Successfully!');
  } finally {
    // Cleanup test user and challenges
    try {
      if (testUserId) {
        await prisma.webAuthnChallenge.deleteMany({ where: { userId: testUserId } });
        await prisma.passkeyCredential.deleteMany({ where: { userId: testUserId } });
        await prisma.hierarchyNode.deleteMany({ where: { userId: testUserId } });
        await prisma.profile.deleteMany({ where: { userId: testUserId } });
        await prisma.user.deleteMany({ where: { id: testUserId } });
      }
    } catch (_) {}
    server.close();
  }
}

runTests().catch((err) => {
  console.error('❌ Passkey Integration Test Failed:', err);
  process.exit(1);
});
