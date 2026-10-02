import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DatabaseModule } from './database/database.module';
import { PasienModule } from './modules/pasien/pasien.module';
import { IstoriaKlinisModule } from './modules/istoria_klinis/istoria_klinis.module';
import { AuthModule } from './modules/auth/auth.module';
import { SyncModule } from './modules/sync/sync.module';

@Module({
  imports: [
    DatabaseModule,
    PasienModule,
    IstoriaKlinisModule,
    AuthModule,
    SyncModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
