import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SyncOperationRecord } from '../../database/entities/sync-operation.record';
import { AuthModule } from '../auth/auth.module';
import { PrescriptionModule } from '../prescription/prescription.module';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';

@Module({
  imports: [AuthModule, PrescriptionModule, TypeOrmModule.forFeature([SyncOperationRecord])],
  controllers: [SyncController],
  providers: [SyncService],
  exports: [SyncService],
})
export class SyncModule {}
