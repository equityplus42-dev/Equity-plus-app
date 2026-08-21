const { execSync } = require('child_process');

try {
  console.log('Pushing Prisma schema to database...');
  const output = execSync('npx prisma db push', { encoding: 'utf-8' });
  console.log(output);
  console.log('Successfully pushed schema to database!');
} catch (error) {
  console.error('Error pushing schema:', error.message);
  if (error.stdout) console.log('stdout:', error.stdout);
  if (error.stderr) console.error('stderr:', error.stderr);
}
