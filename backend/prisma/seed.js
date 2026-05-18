const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');
const { calculateIrd } = require('../src/utils/ird');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed...\n');

  // Clean existing data (respect FK order)
  await prisma.chatMessage.deleteMany();
  await prisma.chatConversation.deleteMany();
  await prisma.healthMetric.deleteMany();
  await prisma.medicalScreening.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.familyProfile.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.article.deleteMany();
  await prisma.region.deleteMany();
  await prisma.user.deleteMany();

  console.log('✅ Cleaned existing data');

  // ─── Users (Family Accounts) ───
  const superadmin = await prisma.user.create({
    data: {
      id: 'superadmin-001',
      kkNumber: '3275000000000001',
      responsibleName: 'Super Admin',
      password: await hashPassword('superadmin123'),
      role: 'SUPERADMIN',
      phone: '08123456789',
    },
  });

  const admin = await prisma.user.create({
    data: {
      id: 'admin-001',
      kkNumber: '3275000000000002',
      responsibleName: 'Admin User',
      password: await hashPassword('admin123'),
      role: 'ADMIN',
      phone: '08123456780',
    },
  });

  const patient = await prisma.user.create({
    data: {
      id: 'patient-001',
      kkNumber: '3275000000000003',
      responsibleName: 'Keluarga Budi',
      password: await hashPassword('patient123'),
      role: 'PATIENT',
      phone: '08123456781',
    },
  });

  console.log('✅ Created family accounts: SUPERADMIN, ADMIN, PATIENT');

  // ─── Family Profiles ───
  const profile1 = await prisma.familyProfile.create({
    data: {
      id: 'profile-001',
      userId: patient.id,
      name: 'Budi Santoso',
      nik: '12131415',
      gender: 'pria',
      birthDate: new Date('1990-01-01'),
      height: 170,
      weight: 75,
      bloodType: 'O',
      phone: '08123456781',
    },
  });

  const profile2 = await prisma.familyProfile.create({
    data: {
      id: 'profile-002',
      userId: patient.id,
      name: 'Siti Aminah',
      nik: '12131416',
      gender: 'wanita',
      birthDate: new Date('1988-05-15'),
      height: 160,
      weight: 65,
      bloodType: 'A',
      phone: '08123456782',
    },
  });

  const profile3 = await prisma.familyProfile.create({
    data: {
      id: 'profile-003',
      userId: patient.id,
      name: 'Dewi Lestari',
      nik: '12131417',
      gender: 'wanita',
      birthDate: new Date('1985-10-20'),
      height: 165,
      weight: 60,
      bloodType: 'B',
      phone: '08123456783',
    },
  });

  const profile4 = await prisma.familyProfile.create({
    data: {
      id: 'profile-004',
      userId: patient.id,
      name: 'Anton Wijaya',
      nik: '12131418',
      gender: 'pria',
      birthDate: new Date('1995-07-12'),
      height: 175,
      weight: 70,
      bloodType: 'AB',
      phone: '08123456784',
    },
  });

  console.log('✅ Created 4 family profiles');

  // ─── Health Metrics ───
  await prisma.healthMetric.createMany({
    data: [
      { profileId: profile1.id, type: 'blood_pressure', value: 120, secondaryValue: 80, unit: 'mmHg', notes: 'Normal', recordedAt: new Date('2026-04-01') },
      { profileId: profile1.id, type: 'blood_pressure', value: 130, secondaryValue: 85, unit: 'mmHg', notes: 'Slightly elevated', recordedAt: new Date('2026-04-15') },
      { profileId: profile1.id, type: 'blood_sugar', value: 110, unit: 'mg/dL', recordedAt: new Date('2026-04-01') },
      { profileId: profile1.id, type: 'cholesterol', value: 200, unit: 'mg/dL', recordedAt: new Date('2026-04-01') },
      { profileId: profile2.id, type: 'blood_pressure', value: 115, secondaryValue: 75, unit: 'mmHg', recordedAt: new Date('2026-04-10') },
    ],
  });

  console.log('✅ Created health metrics');

  // ─── Medical Screenings with IRD ───
  const screeningData1 = {
    bloodSugar: 180, systolic: 130, diastolic: 85,
    cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
  };
  const ird1 = calculateIrd(screeningData1);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile1.id,
      screenedBy: admin.id,
      systolic: 130, diastolic: 85,
      bloodSugar: 180, cholesterol: 220, uricAcid: 6.5,
      height: 170, weight: 75,
      irdScore: ird1.irdScore,
      irdCategory: ird1.irdCategory,
      notes: 'Pemeriksaan rutin April 2026',
      screeningAt: new Date('2026-04-15'),
    },
  });

  const screeningData2 = {
    bloodSugar: 120, systolic: 110, diastolic: 70,
    cholesterol: 180, uricAcid: 4.5, height: 160, weight: 55, gender: 'wanita',
  };
  const ird2 = calculateIrd(screeningData2);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile2.id,
      screenedBy: admin.id,
      systolic: 110, diastolic: 70,
      bloodSugar: 120, cholesterol: 180, uricAcid: 4.5,
      height: 160, weight: 55,
      irdScore: ird2.irdScore,
      irdCategory: ird2.irdCategory,
      notes: 'Pemeriksaan wanita sehat',
      screeningAt: new Date('2026-04-20'),
    },
  });

  const screeningData3 = {
    bloodSugar: 250, systolic: 150, diastolic: 95,
    cholesterol: 280, uricAcid: 8.0, height: 165, weight: 90, gender: 'wanita',
  };
  const ird3 = calculateIrd(screeningData3);

  await prisma.medicalScreening.create({
    data: {
      profileId: profile3.id,
      screenedBy: superadmin.id,
      systolic: 150, diastolic: 95,
      bloodSugar: 250, cholesterol: 280, uricAcid: 8.0,
      height: 165, weight: 90,
      irdScore: ird3.irdScore,
      irdCategory: ird3.irdCategory,
      notes: 'Risiko tinggi, perlu kontrol',
      screeningAt: new Date('2026-04-25'),
    },
  });

  console.log(`✅ Created 3 screenings with IRD:`);
  console.log(`   - ${profile1.name}: ${ird1.irdScore} (${ird1.irdCategory})`);
  console.log(`   - ${profile2.name}: ${ird2.irdScore} (${ird2.irdCategory})`);
  console.log(`   - ${profile3.name}: ${ird3.irdScore} (${ird3.irdCategory})`);

  // ─── Articles ───
  await prisma.article.create({
    data: {
      id: 'article-001',
      authorId: admin.id,
      title: 'Mengenal Diabetes Mellitus',
      content: 'Diabetes mellitus adalah penyakit kronis yang ditandai dengan peningkatan kadar gula darah...',
      tags: ['diabetes', 'kesehatan'],
      isPublished: true,
      isDraft: false,
      publishDate: new Date('2026-04-01'),
    },
  });

  await prisma.article.create({
    data: {
      id: 'article-002',
      authorId: admin.id,
      title: 'Tips Pola Hidup Sehat',
      content: 'Pola hidup sehat dimulai dari makanan bergizi, olahraga teratur, dan istirahat cukup...',
      tags: ['gaya hidup', 'tips'],
      isPublished: true,
      isDraft: false,
      publishDate: new Date('2026-04-10'),
    },
  });

  await prisma.article.create({
    data: {
      id: 'article-003',
      authorId: superadmin.id,
      title: 'Manfaat Tanaman Obat Keluarga (TOGA)',
      content: 'Daun sirsak, jahe, dan kunyit memiliki banyak manfaat untuk kesehatan...',
      tags: ['toga', 'herbal'],
      isPublished: false,
      isDraft: true,
    },
  });

  console.log('✅ Created 3 articles (2 published, 1 draft)');

  // ─── Regions ───
  const rw = await prisma.region.create({
    data: { id: 'region-001', type: 'RW', name: 'RW 05' },
  });

  const rt = await prisma.region.create({
    data: { id: 'region-002', type: 'RT', name: 'RT 02', parentId: rw.id },
  });

  console.log('✅ Created RW/RT structure');

  // ─── Link PATIENT user to RT ───
  await prisma.user.update({
    where: { id: patient.id },
    data: { regionId: rt.id },
  });

  console.log('✅ Linked patient account to RT');

  // ─── Appointments ───
  const startOfToday = new Date();
  startOfToday.setHours(9, 0, 0, 0);
  const inDays = (n, hour = 9) => {
    const d = new Date(startOfToday);
    d.setDate(d.getDate() + n);
    d.setHours(hour, 0, 0, 0);
    return d;
  };

  await prisma.appointment.createMany({
    data: [
      {
        userId: admin.id,
        title: 'Screening Diabetes Massal',
        date: inDays(0, 9),
        location: 'Posyandu Desa Sukamaju',
        notes: 'dr. Ratna Sari',
        type: 'SCREENING',
      },
      {
        userId: admin.id,
        title: 'Monitoring Hipertensi',
        date: inDays(3, 10),
        location: 'Balai Desa Sukamaju',
        notes: 'dr. Bagus Pratama',
        type: 'MONITORING',
      },
      {
        userId: admin.id,
        title: 'Pemeriksaan Lansia',
        date: inDays(7, 8),
        location: 'Puskesmas Sehat',
        notes: 'dr. Indah Permata',
        type: 'GENERAL',
      },
    ],
  });

  console.log('✅ Created 3 appointments');

  console.log('\n🎉 Seed completed successfully!');
  console.log('\nLogin credentials:');
  console.log('  SUPERADMIN: KK=3275000000000001, password=superadmin123');
  console.log('  ADMIN:      KK=3275000000000002, password=admin123');
  console.log('  PATIENT:    KK=3275000000000003, password=patient123');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
