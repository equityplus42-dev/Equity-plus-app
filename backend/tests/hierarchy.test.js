const assert = require('assert');
const http = require('http');
const app = require('../src/app');
const prisma = require('../src/config/database');

async function runTests() {
  console.log('Running Hierarchy and Referral Rewards Integration Tests...');

  const server = http.createServer(app);
  server.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  const time = Date.now();
  const emailA = `usera_${time}@example.com`;
  const emailB = `userb_${time}@example.com`;
  const emailC = `userc_${time}@example.com`;
  
  let userA, userB, userC;
  let tokenA;

  try {
    // 1. Setup default configurations (force points level 1 = 100, level 2 = 50, require approval = false)
    await prisma.systemSettings.upsert({
      where: { key: 'points_level_1' },
      update: { value: '100' },
      create: { key: 'points_level_1', value: '100' }
    });
    await prisma.systemSettings.upsert({
      where: { key: 'points_level_2' },
      update: { value: '50' },
      create: { key: 'points_level_2', value: '50' }
    });
    await prisma.systemSettings.upsert({
      where: { key: 'require_admin_approval' },
      update: { value: 'false' },
      create: { key: 'require_admin_approval', value: 'false' }
    });

    // 2. Register User A (Root)
    console.log('- Registering root User A...');
    const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    const refCode = admin ? admin.referralCode : 'ADMINREF';
    
    const resA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: emailA, password: 'Password123!', firstName: 'User', lastName: 'A', referralCode: refCode })
    });
    assert.strictEqual(resA.status, 201);
    const jsonA = await resA.json();
    userA = jsonA.data.user;
    tokenA = jsonA.data.token;

    // 3. Register User B referred by User A
    console.log('- Registering User B using A\'s referral code...');
    const resB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: emailB,
        password: 'Password123!',
        firstName: 'User',
        lastName: 'B',
        phoneNumber: '9876543210',
        referralCode: userA.referralCode
      })
    });
    assert.strictEqual(resB.status, 201);
    const jsonB = await resB.json();
    userB = jsonB.data.user;

    // 4. Register User C referred by User B
    console.log('- Registering User C using B\'s referral code...');
    const resC = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: emailC,
        password: 'Password123!',
        firstName: 'User',
        lastName: 'C',
        phoneNumber: '8765432109',
        referralCode: userB.referralCode
      })
    });
    assert.strictEqual(resC.status, 201);
    const jsonC = await resC.json();
    userC = jsonC.data.user;

    // 5. Verify Hierarchy Nodes
    console.log('- Verifying hierarchy paths...');
    const nodeA = await prisma.hierarchyNode.findUnique({ where: { userId: userA.id } });
    const nodeB = await prisma.hierarchyNode.findUnique({ where: { userId: userB.id } });
    const nodeC = await prisma.hierarchyNode.findUnique({ where: { userId: userC.id } });

    const adminId = admin ? admin.id : '00000000-0000-0000-0000-000000000000';

    assert.strictEqual(nodeA.level, 1);
    assert.strictEqual(nodeA.parentId, adminId);
    assert.strictEqual(nodeA.path, `/${adminId}/${userA.id}`);

    assert.strictEqual(nodeB.level, 2);
    assert.strictEqual(nodeB.parentId, userA.id);
    assert.strictEqual(nodeB.path, `/${adminId}/${userA.id}/${userB.id}`);

    assert.strictEqual(nodeC.level, 3);
    assert.strictEqual(nodeC.parentId, userB.id);
    assert.strictEqual(nodeC.path, `/${adminId}/${userA.id}/${userB.id}/${userC.id}`);

    // 6. Verify Rewards Points distributed
    // When B signs up (referred by A) -> A gets 100 points
    // When C signs up (referred by B) -> B gets 100 points (L1), A gets 50 points (L2)
    // Total: A should have 150 points, B should have 100 points, C should have 0 points
    console.log('- Checking awarded points balances...');
    const dbUserA = await prisma.user.findUnique({ where: { id: userA.id } });
    const dbUserB = await prisma.user.findUnique({ where: { id: userB.id } });
    const dbUserC = await prisma.user.findUnique({ where: { id: userC.id } });

    assert.strictEqual(dbUserA.points, 150);
    assert.strictEqual(dbUserB.points, 100);
    assert.strictEqual(dbUserC.points, 0);

    // 7. Get User A's hierarchy tree via API
    console.log('- Testing hierarchy tree API endpoint...');
    const treeRes = await fetch(`${baseUrl}/hierarchy`, {
      headers: { Authorization: `Bearer ${tokenA}` }
    });
    assert.strictEqual(treeRes.status, 200);
    const treeJson = await treeRes.json();
    assert.strictEqual(treeJson.success, true);
    
    // Root level in returned array should be User A
    const treeData = treeJson.data;
    assert.strictEqual(treeData.length, 1);
    assert.strictEqual(treeData[0].email, emailA);
    // User A should have User B as child (email property should be masked to their phoneNumber)
    assert.strictEqual(treeData[0].children.length, 1);
    assert.strictEqual(treeData[0].children[0].email, '9876543210');
    // User B should have User C as child (email property should be masked to their phoneNumber)
    assert.strictEqual(treeData[0].children[0].children.length, 1);
    assert.strictEqual(treeData[0].children[0].children[0].email, '8765432109');

    console.log('✅ Hierarchy and Rewards tests passed successfully.');
  } catch (err) {
    console.error('❌ Hierarchy and Rewards tests failed:', err);
    process.exitCode = 1;
  } finally {
    // DB cleanups
    const emails = [emailA, emailB, emailC];
    try {
      await prisma.profile.deleteMany({ where: { user: { email: { in: emails } } } });
      await prisma.hierarchyNode.deleteMany({ where: { user: { email: { in: emails } } } });
      await prisma.referral.deleteMany({ where: { referrer: { email: { in: emails } } } });
      await prisma.referral.deleteMany({ where: { referee: { email: { in: emails } } } });
      await prisma.user.deleteMany({ where: { email: { in: emails } } });
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
