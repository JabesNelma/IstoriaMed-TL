import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { MedicationRecord } from '../../database/entities/medication.record';
import { PrescriptionItemRecord } from '../../database/entities/prescription-item.record';
import { PrescriptionRecord } from '../../database/entities/prescription.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { AuthModule } from '../auth/auth.module';
import { MedicationService } from './medication.service';
import {
  MedicationAdminController,
  MedicationController,
  PrescriptionController,
} from './prescription.controller';
import { PrescriptionService } from './prescription.service';

@Module({
  imports: [
    AuthModule,
    TypeOrmModule.forFeature([
      MedicationRecord,
      PrescriptionRecord,
      PrescriptionItemRecord,
      ClinicalVisitRecord,
      StaffRecord,
    ]),
  ],
  controllers: [PrescriptionController, MedicationController, MedicationAdminController],
  providers: [PrescriptionService, MedicationService],
  exports: [PrescriptionService, MedicationService],
})
export class PrescriptionModule {}