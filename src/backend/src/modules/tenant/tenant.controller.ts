import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';

import { AuthGuard } from '../auth/auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { CreateTenantDto, SearchTenantDto, UpdateTenantDto } from './dto/tenant.dto';
import { TenantEntity } from './tenant.entity';
import { TenantService } from './tenant.service';

/**
 * Tenant administration endpoints.
 *
 * PRD 4.3 places tenant authority at the central level (the ministry): only the
 * two administrative roles may create, inspect, rename or suspend a tenant. No
 * facility level operator can elevate itself into tenant management.
 */
@Controller('api/admin/tenants')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN')
export class TenantAdminController {
  constructor(private readonly tenantService: TenantService) {}

  @Post()
  create(@Body() data: CreateTenantDto): Promise<TenantEntity> {
    return this.tenantService.create(data);
  }

  @Get()
  findAll(@Query() search: SearchTenantDto): Promise<TenantEntity[]> {
    return this.tenantService.findAll(search);
  }

  @Get(':tenantId')
  findOne(@Param('tenantId') tenantId: string): Promise<TenantEntity> {
    return this.tenantService.findOne(tenantId);
  }

  @Patch(':tenantId')
  update(@Param('tenantId') tenantId: string, @Body() data: UpdateTenantDto): Promise<TenantEntity> {
    return this.tenantService.update(tenantId, data);
  }
}
