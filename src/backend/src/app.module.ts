import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from './database/database.module';
import { PasienModule } from './modules/pasien/pasien.module';
import { IstoriaKlinisModule } from './modules/istoria_klinis/istoria_klinis.module';
import { AuthModule } from './modules/auth/auth.module';

@Module({
  imports: [
    DatabaseModule,
    PasienModule,
    IstoriaKlinisModule,
    AuthModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
