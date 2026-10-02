import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { getDatabaseOptions } from './database.config';
import { ClinicalVisitRecord } from './entities/clinical-visit.record';
import { PatientRecord } from './entities/patient.record';
import { UserRecord } from './entities/user.record';
import { FacilityRecord } from './entities/facility.record';
import { FacilityMembershipRecord } from './entities/facility-membership.record';
import { StaffRecord } from './entities/staff.record';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      useFactory: getDatabaseOptions,
    }),
    TypeOrmModule.forFeature([PatientRecord, ClinicalVisitRecord, UserRecord, FacilityRecord, FacilityMembershipRecord, StaffRecord]),
  ],
  exports: [TypeOrmModule],
})
export class DatabaseModule {}
