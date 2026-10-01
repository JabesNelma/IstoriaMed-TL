import { ConflictException, Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PasienEntity } from './pasien.entity';

@Injectable()
export class PasienService {
	private databasePasien: PasienEntity[] = [];

	create(
		data: Omit<PasienEntity, 'user_id' | 'tanggal_terdaftar'>,
	): PasienEntity {
		const pasienSudahAda = this.databasePasien.some(
			(pasien) => pasien.no_ktp === data.no_ktp,
		);

		if (pasienSudahAda) {
			throw new ConflictException("KTP ne'e rejistradu ona!");
		}

		const pasienBaru: PasienEntity = {
			...data,
			user_id: randomUUID(),
			tanggal_terdaftar: new Date(),
		};

		this.databasePasien.push(pasienBaru);
		return pasienBaru;
	}

	findAll(): PasienEntity[] {
		return this.databasePasien;
	}

	findOne(id: string): PasienEntity | undefined {
		return this.databasePasien.find((pasien) => pasien.user_id === id);
	}
}
