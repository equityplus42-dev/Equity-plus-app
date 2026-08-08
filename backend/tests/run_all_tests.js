const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function runAllBackendTestFiles() {
  console.log('🚀 Running Complete VRIDHI Backend Test Suite...\n');
  const testsDir = __dirname;
  const files = fs.readdirSync(testsDir).filter(f => f.endsWith('.test.js'));

  let totalFiles = files.length;
  let passedFiles = 0;
  let failedFiles = 0;

  for (const file of files) {
    const filePath = path.join(testsDir, file);
    console.log(`▶ Executing ${file}...`);
    try {
      const output = execSync(`node "${filePath}"`, { encoding: 'utf8' });
      console.log(output.trim());
      console.log(`✅ ${file} PASSED\n`);
      passedFiles++;
    } catch (err) {
      console.error(`❌ ${file} FAILED:`);
      console.error(err.stdout || err.message);
      failedFiles++;
    }
  }

  console.log('==================================================');
  console.log(`📊 TEST SUITE SUMMARY:`);
  console.log(`   Total Test Files: ${totalFiles}`);
  console.log(`   Passed: ${passedFiles}`);
  console.log(`   Failed: ${failedFiles}`);
  console.log('==================================================');
}

runAllBackendTestFiles();
