import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { TenantRecord } from '../../database/entities/tenant.record';
import { AuthModule } from '../auth/auth.module';
import { TenantAdminController } from './tenant.controller';
import { TenantService } from './tenant.service';

@Module({
  imports: [AuthModule, TypeOrmModule.forFeature([TenantRecord])],
  controllers: [TenantAdminController],
  providers: [TenantService],
  exports: [TenantService],
})
export class TenantModule {}
