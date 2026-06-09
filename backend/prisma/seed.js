const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...\n');

  const password = await hashPassword('Mediku@2026!');

  const superadmins = [
    { id: 'superadmin-wati',  username: 'superadmin.wati',  responsibleName: 'Wati'  },
    { id: 'superadmin-aidut', username: 'superadmin.aidut', responsibleName: 'Aidut' },
    { id: 'superadmin-qyu',   username: 'superadmin.qyu',   responsibleName: 'Qyu'   },
  ];

  for (const sa of superadmins) {
    await prisma.user.upsert({
      where: { id: sa.id },
      update: {},
      create: { ...sa, password, role: 'SUPERADMIN' },
    });
  }

  console.log('✅ Ensured 3 superadmin accounts exist');

  // Dev-only fixture: tests/conflict.test.js and tests/websocket.test.js log in
  // as this patient. Without it the suite fails on a freshly-seeded database.
  if (process.env.NODE_ENV !== 'production') {
    await prisma.user.upsert({
      where: { kkNumber: '3275000000000003' },
      update: {},
      create: {
        kkNumber: '3275000000000003',
        responsibleName: 'Test Patient Fixture',
        password: await hashPassword('patient123'),
        role: 'PATIENT',
        phone: '08120000003',
      },
    });
    console.log('✅ Ensured test fixture patient (3275000000000003 / patient123) exists');
  }

  console.log('\n🎉 Seed completed successfully!');
  console.log('\nLogin credentials (change passwords before real users onboard):');
  console.log('  SUPERADMIN: username=superadmin.wati  password=Mediku@2026!');
  console.log('  SUPERADMIN: username=superadmin.aidut password=Mediku@2026!');
  console.log('  SUPERADMIN: username=superadmin.qyu   password=Mediku@2026!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
