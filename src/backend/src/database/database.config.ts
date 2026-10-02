import type { DataSourceOptions } from 'typeorm';

import { ClinicalVisitRecord } from './entities/clinical-visit.record';
import { PatientRecord } from './entities/patient.record';
import { UserRecord } from './entities/user.record';
import { FacilityRecord } from './entities/facility.record';
import { FacilityMembershipRecord } from './entities/facility-membership.record';
import { StaffRecord } from './entities/staff.record';

export function getDatabaseOptions(): DataSourceOptions {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error('DATABASE_URL is required to start the backend.');
  }

  return {
    type: 'postgres',
    url,
    entities: [PatientRecord, ClinicalVisitRecord, UserRecord, FacilityRecord, FacilityMembershipRecord, StaffRecord],
    migrations: ['dist/database/migrations/*.js'],
    synchronize: false,
    migrationsRun: false,
    ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
  };
}
