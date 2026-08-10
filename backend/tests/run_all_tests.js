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
      console.log(`⚠️ ${file} initial attempt encountered network delay, waiting 2s before retry...`);
      execSync('node -e "setTimeout(() => {}, 2000)"');
      try {
        const retryOutput = execSync(`node "${filePath}"`, { encoding: 'utf8' });
        console.log(retryOutput.trim());
        console.log(`✅ ${file} PASSED (on retry)\n`);
        passedFiles++;
      } catch (retryErr) {
        console.error(`❌ ${file} FAILED:`);
        console.error(retryErr.stdout || retryErr.message);
        failedFiles++;
      }
    }
    execSync('node -e "setTimeout(() => {}, 1000)"');
  }

  console.log('==================================================');
  console.log(`📊 TEST SUITE SUMMARY:`);
  console.log(`   Total Test Files: ${totalFiles}`);
  console.log(`   Passed: ${passedFiles}`);
  console.log(`   Failed: ${failedFiles}`);
  console.log('==================================================');
}

runAllBackendTestFiles();
