import { Module } from '@nestjs/common';
import { PasienController } from './pasien.controller';
import { PasienService } from './pasien.service';

@Module({
  controllers: [PasienController],
  providers: [PasienService],
  exports: [PasienService],
})
export class PasienModule {}
