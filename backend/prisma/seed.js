const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...\n');

  // Clean existing data (respect FK order)
  await prisma.healthMetric.deleteMany();
  await prisma.medicalScreening.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.familyProfile.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.article.deleteMany();
  await prisma.region.deleteMany();
  await prisma.user.deleteMany();
  await prisma.tokenBlacklist.deleteMany();

  console.log('✅ Cleaned existing data');

  const password = await hashPassword('Mediku@2026!');

  await prisma.user.createMany({
    data: [
      {
        id: 'superadmin-wati',
        username: 'superadmin.wati',
        responsibleName: 'Wati',
        password,
        role: 'SUPERADMIN',
      },
      {
        id: 'superadmin-aidut',
        username: 'superadmin.aidut',
        responsibleName: 'Aidut',
        password,
        role: 'SUPERADMIN',
      },
      {
        id: 'superadmin-qyu',
        username: 'superadmin.qyu',
        responsibleName: 'Qyu',
        password,
        role: 'SUPERADMIN',
      },
    ],
  });

  console.log('✅ Created 3 superadmin accounts');
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
