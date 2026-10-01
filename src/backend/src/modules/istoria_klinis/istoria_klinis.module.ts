import { Module } from '@nestjs/common';
import { IstoriaKlinisController } from './istoria_klinis.controller';
import { IstoriaKlinisService } from './istoria_klinis.service';
import { PasienModule } from '../pasien/pasien.module';

@Module({
  imports: [PasienModule],
  controllers: [IstoriaKlinisController],
  providers: [IstoriaKlinisService],
})
export class IstoriaKlinisModule {}
