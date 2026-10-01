import { Body, Controller, Get, Post } from '@nestjs/common';
import { PasienEntity } from './pasien.entity';
import { PasienService } from './pasien.service';

@Controller('api/pasien')
export class PasienController {
	constructor(private readonly pasienService: PasienService) {}

	@Post('register')
	register(
		@Body() data: Omit<PasienEntity, 'user_id' | 'tanggal_terdaftar'>,
	): { success: true; message: string; data: PasienEntity[] } {
		const pasienBaru = this.pasienService.create(data);

		return {
			success: true,
			message: 'Dados pasiente rejistradu ho susesu!',
			data: [pasienBaru],
		};
	}

	@Get()
	findAll(): PasienEntity[] {
		return this.pasienService.findAll();
	}
}
