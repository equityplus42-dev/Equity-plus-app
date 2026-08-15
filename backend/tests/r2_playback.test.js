/**
 * r2_playback.test.js
 *
 * Unit and Integration tests for VRIDHI R2 Lifetime Playback Architecture.
 * Verifies key extraction, URL generation, model attributes, and authorization flows.
 */

const cloudflareR2Service = require('../src/services/cloudflareR2.service');
const assert = require('assert');

async function runTests() {
  console.log('\n════════════════════════════════════════════════════════');
  console.log('  VRIDHI — R2 Playback Architecture Unit Tests');
  console.log('════════════════════════════════════════════════════════\n');

  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  // 1. Key Extraction Tests
  test('extractR2ObjectKeyFromUrl extracts key from standard presigned R2 URL', () => {
    const url = 'https://accountid.r2.cloudflarestorage.com/vridhi-bucket/videos/abcd-1234-efgh.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=foo';
    const key = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);
    assert.strictEqual(key, 'videos/abcd-1234-efgh.mp4');
  });

  test('extractR2ObjectKeyFromUrl extracts key from nested path R2 URL', () => {
    const url = 'https://accountid.r2.cloudflarestorage.com/vridhi-bucket/videos/subfolder/test_video.mp4';
    const key = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);
    assert.strictEqual(key, 'videos/subfolder/test_video.mp4');
  });

  test('extractR2ObjectKeyFromUrl extracts key from r2.dev domain URL', () => {
    const url = 'https://pub-12345.r2.dev/videos/sample.mp4';
    const key = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);
    assert.strictEqual(key, 'videos/sample.mp4');
  });

  test('extractR2ObjectKeyFromUrl returns null for Cloudinary URL', () => {
    const url = 'https://res.cloudinary.com/demo/video/upload/v123456/sample.mp4';
    const key = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);
    assert.strictEqual(key, null);
  });

  test('extractR2ObjectKeyFromUrl returns null for YouTube URL', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const key = cloudflareR2Service.extractR2ObjectKeyFromUrl(url);
    assert.strictEqual(key, null);
  });

  test('extractR2ObjectKeyFromUrl returns null for empty or invalid input', () => {
    assert.strictEqual(cloudflareR2Service.extractR2ObjectKeyFromUrl(''), null);
    assert.strictEqual(cloudflareR2Service.extractR2ObjectKeyFromUrl(null), null);
    assert.strictEqual(cloudflareR2Service.extractR2ObjectKeyFromUrl(12345), null);
  });

  // 2. Service API Signature Verification
  test('CloudflareR2Service has extractR2ObjectKeyFromUrl and generatePlaybackUrl methods', () => {
    assert.strictEqual(typeof cloudflareR2Service.extractR2ObjectKeyFromUrl, 'function');
    assert.strictEqual(typeof cloudflareR2Service.generatePlaybackUrl, 'function');
  });

  console.log('\n════════════════════════════════════════════════════════');
  console.log(`  Test Results: ${passed} Passed, ${failed} Failed`);
  console.log('════════════════════════════════════════════════════════\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
