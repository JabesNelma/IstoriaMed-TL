import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { AuthModule } from '../auth/auth.module';
import { IstoriaKlinisController } from './istoria_klinis.controller';
import { IstoriaKlinisService } from './istoria_klinis.service';
import { PasienModule } from '../pasien/pasien.module';

@Module({
  imports: [PasienModule, TypeOrmModule.forFeature([ClinicalVisitRecord, StaffRecord]), AuthModule],
  controllers: [IstoriaKlinisController],
  providers: [IstoriaKlinisService],
})
export class IstoriaKlinisModule {}
