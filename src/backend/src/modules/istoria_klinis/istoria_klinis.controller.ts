import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { IstoriaKlinisEntity } from './istoria-klinis.entity';
import { IstoriaKlinisService } from './istoria_klinis.service';

@Controller('api/istoria-klinis')
export class IstoriaKlinisController {
	constructor(private readonly istoriaKlinisService: IstoriaKlinisService) {}

	@Post('create')
	create(
		@Body()
		data: Omit<
			IstoriaKlinisEntity,
			'kunjungan_id' | 'tanggal_kunjungan' | 'status_sinkronisasi'
		>,
	): IstoriaKlinisEntity {
		return this.istoriaKlinisService.create(data);
	}

	@Get('pasien/:pasienId')
	findByPatient(@Param('pasienId') pasienId: string): IstoriaKlinisEntity[] {
		return this.istoriaKlinisService.findByPatient(pasienId);
	}

	@Get('tenant/:tenantId')
	findByTenant(@Param('tenantId') tenantId: string): IstoriaKlinisEntity[] {
		return this.istoriaKlinisService.findByTenant(tenantId);
	}
}
