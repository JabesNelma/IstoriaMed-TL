import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PasienModule } from './modules/pasien/pasien.module';
import { IstoriaKlinisModule } from './modules/istoria_klinis/istoria_klinis.module';

@Module({
  imports: [
    PasienModule,
    IstoriaKlinisModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
