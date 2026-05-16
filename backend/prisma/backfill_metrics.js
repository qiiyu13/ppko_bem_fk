const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('Backfilling health_metrics from existing medical_screenings...\n');

  const screenings = await prisma.medicalScreening.findMany({
    orderBy: { screeningAt: 'asc' },
  });

  console.log(`Found ${screenings.length} medical_screenings\n`);

  let created = 0;
  let skipped = 0;

  for (const s of screenings) {
    const metricRows = [];

    if (s.systolic != null && s.diastolic != null) {
      metricRows.push({
        profileId: s.profileId,
        type: 'blood_pressure',
        value: s.systolic,
        secondaryValue: s.diastolic,
        unit: 'mmHg',
        recordedAt: s.screeningAt,
      });
    }
    if (s.bloodSugar != null) {
      metricRows.push({
        profileId: s.profileId,
        type: 'blood_sugar',
        value: s.bloodSugar,
        unit: 'mg/dL',
        recordedAt: s.screeningAt,
      });
    }
    if (s.cholesterol != null) {
      metricRows.push({
        profileId: s.profileId,
        type: 'cholesterol',
        value: s.cholesterol,
        unit: 'mg/dL',
        recordedAt: s.screeningAt,
      });
    }
    if (s.uricAcid != null) {
      metricRows.push({
        profileId: s.profileId,
        type: 'uric_acid',
        value: s.uricAcid,
        unit: 'mg/dL',
        recordedAt: s.screeningAt,
      });
    }

    for (const row of metricRows) {
      const existing = await prisma.healthMetric.findFirst({
        where: {
          profileId: row.profileId,
          type: row.type,
          recordedAt: row.recordedAt,
        },
      });

      if (!existing) {
        await prisma.healthMetric.create({ data: row });
        created++;
        console.log(`  + ${row.type} for profile ${row.profileId} (${s.screeningAt.toISOString()})`);
      } else {
        skipped++;
      }
    }
  }

  console.log(`\nDone: ${created} metrics created, ${skipped} skipped (already exist)`);
}

main()
  .catch((e) => {
    console.error('Backfill failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
