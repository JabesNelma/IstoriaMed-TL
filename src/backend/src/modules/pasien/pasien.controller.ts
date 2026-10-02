import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { AuthGuard, getAuthenticatedUser } from '../auth/auth.guard';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { RegisterPasienDto } from './dto/register-pasien.dto';
import { SearchPatientDto, UpdatePatientDto } from './dto/patient.dto';
import { PasienEntity } from './pasien.entity';
import { PasienService } from './pasien.service';

@Controller('api/pasien')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE')
export class PasienController {
	constructor(private readonly pasienService: PasienService) {}

	@Post('register')
	register(
		@Body() data: RegisterPasienDto,
		@Req() request: AuthenticatedRequest,
	): Promise<{ success: true; message: string; data: PasienEntity[] }> {
		return this.pasienService.create(data, getAuthenticatedUser(request)).then((pasienBaru) => ({
			success: true,
			message: 'Dados pasiente rejistradu ho susesu!',
			data: [pasienBaru],
		}));
	}

	@Get()
	findAll(@Req() request: AuthenticatedRequest, @Query() search: SearchPatientDto): Promise<PasienEntity[]> {
		return this.pasienService.findAll(getAuthenticatedUser(request), search);
	}

	@Get(':id')
	findOne(@Param('id') id: string, @Req() request: AuthenticatedRequest): Promise<PasienEntity> {
		return this.pasienService.findOneForUser(id, getAuthenticatedUser(request));
	}

	@Patch(':id')
	update(@Param('id') id: string, @Body() data: UpdatePatientDto, @Req() request: AuthenticatedRequest): Promise<PasienEntity> {
		return this.pasienService.update(id, data, getAuthenticatedUser(request));
	}
}
