import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PatientRecord } from '../../database/entities/patient.record';
import { AuthModule } from '../auth/auth.module';
import { PasienController } from './pasien.controller';
import { PasienService } from './pasien.service';

@Module({
  controllers: [PasienController],
  imports: [TypeOrmModule.forFeature([PatientRecord]), AuthModule],
  providers: [PasienService],
  exports: [PasienService],
})
export class PasienModule {}
