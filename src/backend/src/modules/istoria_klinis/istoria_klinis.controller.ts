import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard, getAuthenticatedUser } from '../auth/auth.guard';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { CreateIstoriaKlinisDto, UpdateIstoriaKlinisDto } from './dto/create-istoria-klinis.dto';
import { IstoriaKlinisEntity } from './istoria-klinis.entity';
import { IstoriaKlinisService } from './istoria_klinis.service';

@Controller('api/istoria-klinis')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE')
export class IstoriaKlinisController {
	constructor(private readonly istoriaKlinisService: IstoriaKlinisService) {}

	@Post('create')
	create(
		@Body()
		data: CreateIstoriaKlinisDto,
		@Req() request: AuthenticatedRequest,
	): Promise<IstoriaKlinisEntity> {
		return this.istoriaKlinisService.create(data, getAuthenticatedUser(request));
	}

	@Get()
	findAll(@Req() request: AuthenticatedRequest): Promise<IstoriaKlinisEntity[]> {
		return this.istoriaKlinisService.findAll(getAuthenticatedUser(request));
	}

	@Get(':id')
	findOne(@Param('id') id: string, @Req() request: AuthenticatedRequest): Promise<IstoriaKlinisEntity> {
		return this.istoriaKlinisService.findOne(id, getAuthenticatedUser(request));
	}

	@Get('pasien/:pasienId')
	findByPatient(@Param('pasienId') pasienId: string, @Req() request: AuthenticatedRequest): Promise<IstoriaKlinisEntity[]> {
		return this.istoriaKlinisService.findByPatient(pasienId, getAuthenticatedUser(request));
	}

	@Get('tenant/:tenantId')
	findByTenant(@Param('tenantId') tenantId: string, @Req() request: AuthenticatedRequest): Promise<IstoriaKlinisEntity[]> {
		return this.istoriaKlinisService.findByTenant(tenantId, getAuthenticatedUser(request));
	}

	@Patch(':id')
	update(@Param('id') id: string, @Body() data: UpdateIstoriaKlinisDto, @Req() request: AuthenticatedRequest): Promise<IstoriaKlinisEntity> {
		return this.istoriaKlinisService.update(id, data, getAuthenticatedUser(request));
	}
}
