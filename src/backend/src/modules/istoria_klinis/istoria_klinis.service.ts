import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PasienService } from '../pasien/pasien.service';
import { IstoriaKlinisEntity } from './istoria-klinis.entity';

@Injectable()
export class IstoriaKlinisService {
	private databaseKlinis: IstoriaKlinisEntity[] = [];

	constructor(private readonly pasienService: PasienService) {}

	create(
		data: Omit<
			IstoriaKlinisEntity,
			'kunjungan_id' | 'tanggal_kunjungan' | 'status_sinkronisasi'
		>,
	): IstoriaKlinisEntity {
		const pasien = this.pasienService.findOne(data.pasien_id);
		if (!pasien) {
			throw new NotFoundException("Pasiente ho ID ne'e la hetan!");
		}

		const kunjunganBaru: IstoriaKlinisEntity = {
			...data,
			kunjungan_id: randomUUID(),
			tanggal_kunjungan: new Date(),
			status_sinkronisasi: 'Pending',
		};

		this.databaseKlinis.push(kunjunganBaru);
		return kunjunganBaru;
	}

	findByPatient(pasienId: string): IstoriaKlinisEntity[] {
		return this.databaseKlinis.filter(
			(kunjungan) => kunjungan.pasien_id === pasienId,
		);
	}

	findByTenant(tenantId: string): IstoriaKlinisEntity[] {
		return this.databaseKlinis.filter(
			(kunjungan) => kunjungan.tenant_id === tenantId,
		);
	}
}
