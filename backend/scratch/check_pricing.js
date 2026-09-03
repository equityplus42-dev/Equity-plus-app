const prisma = require('../src/config/database');

async function main() {
  try {
    const products = await prisma.product.findMany({
      orderBy: { createdAt: 'asc' }
    });

    const allSettings = await prisma.systemSettings.findMany();

    console.log('=== VRIDHI NETWORK PRICING & PRODUCTS ===');
    console.log(`Total Products in Database: ${products.length}\n`);

    products.forEach((p, i) => {
      console.log(`Product #${i + 1}: ${p.name} (Code: ${p.code || 'N/A'})`);
      console.log(`- ID: ${p.id}`);
      console.log(`- Price: ₹${p.price}`);
      console.log(`- Description: ${p.description || 'N/A'}`);
      console.log(`- Status: ${p.status}`);
      console.log(`- Created At: ${p.createdAt}`);
      console.log('-----------------------------------');
    });

    console.log('\n=== SYSTEM SETTINGS (OVERRIDDEN PRICING / DEFAULTS) ===');
    if (allSettings.length === 0) {
      console.log('No custom SystemSettings pricing overrides found. Database default product price is active.');
    } else {
      console.log(JSON.stringify(allSettings, null, 2));
    }
  } catch (err) {
    console.error('Error checking pricing:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
