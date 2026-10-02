import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { PasienService } from '../pasien/pasien.service';
import { CreateIstoriaKlinisDto, UpdateIstoriaKlinisDto } from './dto/create-istoria-klinis.dto';
import { IstoriaKlinisEntity } from './istoria-klinis.entity';
import { AuthenticatedUser } from '../auth/auth.types';

@Injectable()
export class IstoriaKlinisService {
	constructor(
		private readonly pasienService: PasienService,
		@InjectRepository(ClinicalVisitRecord)
		private readonly visitRepository: Repository<ClinicalVisitRecord>,
		@InjectRepository(StaffRecord)
		private readonly staffRepository: Repository<StaffRecord>,
	) {}

	async create(
		data: CreateIstoriaKlinisDto,
		user: AuthenticatedUser,
	): Promise<IstoriaKlinisEntity> {
		const membership = user.memberships.find((item) => data.tenant_id ? item.tenant_id === data.tenant_id : true) ?? user.memberships[0];
		if (!membership) throw new ForbiddenException('Facility access denied.');
		if (data.tenant_id && data.tenant_id !== membership.tenant_id) {
			throw new ForbiddenException('Tenant access denied.');
		}
		const staff = await this.staffRepository.findOne({
			where: { user_id: user.user_id, facility_id: membership.facility_id, verification_status: 'Approved' },
		});
		if (!staff) throw new ForbiddenException('A verified staff profile is required for clinical visits.');

		const pasien = await this.pasienService.findOne(data.pasien_id);
		if (!pasien) {
			throw new NotFoundException("Pasiente ho ID ne'e la hetan!");
		}
		if (pasien.facility_id && pasien.facility_id !== membership.facility_id) {
			throw new ForbiddenException('Patient facility access denied.');
		}

		const now = new Date();
		const record = this.visitRepository.create({
			kunjungan_id: randomUUID(),
			pasien_id: data.pasien_id,
			facility_id: membership.facility_id,
			tenant_id: membership.tenant_id,
			staf_id: staff.staff_id,
			tanggal_kunjungan: new Date(data.visit_date ?? now),
			keluhan_subjektif: data.keluhan_subjektif,
			pemeriksaan_objektif: data.pemeriksaan_objektif ?? null,
			analisis_asesmen: data.analisis_asesmen ?? null,
			rencana_tindakan: data.rencana_tindakan ?? null,
			kode_icd10: data.kode_icd10,
			nama_penyakit_lokal: data.nama_penyakit_lokal ?? null,
			status_sinkronisasi: 'Pending',
			created_at: now,
			updated_at: now,
		});

		return this.toEntity(await this.visitRepository.save(record));
	}

	async findAll(user: AuthenticatedUser): Promise<IstoriaKlinisEntity[]> {
		const facilityIds = [...new Set(user.memberships.map((item) => item.facility_id))];
		const tenantIds = [...new Set(user.memberships.map((item) => item.tenant_id))];
		if (!facilityIds.length && !tenantIds.length) return [];
		const records = await this.visitRepository.createQueryBuilder('visit')
			.where('(visit.facility_id IN (:...facilityIds) OR visit.tenant_id IN (:...tenantIds))', { facilityIds, tenantIds })
			.orderBy('visit.tanggal_kunjungan', 'DESC')
			.getMany();
		return records.map((record) => this.toEntity(record));
	}

	async findOne(id: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity> {
		const facilityIds = [...new Set(user.memberships.map((item) => item.facility_id))];
		const tenantIds = [...new Set(user.memberships.map((item) => item.tenant_id))];
		const record = await this.visitRepository.createQueryBuilder('visit')
			.where('visit.kunjungan_id = :id', { id })
			.andWhere('(visit.facility_id IN (:...facilityIds) OR visit.tenant_id IN (:...tenantIds))', { facilityIds, tenantIds })
			.getOne();
		if (!record) throw new NotFoundException('Clinical visit not found.');
		return this.toEntity(record);
	}

	async findByPatient(pasienId: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity[]> {
		const facilityIds = [...new Set(user.memberships.map((item) => item.facility_id))];
		const tenantIds = [...new Set(user.memberships.map((item) => item.tenant_id))];
		const patient = await this.pasienService.findOneForUser(pasienId, user);
		const records = await this.visitRepository.createQueryBuilder('visit')
			.where('visit.pasien_id = :pasienId', { pasienId })
			.andWhere('(visit.facility_id IN (:...facilityIds) OR visit.tenant_id IN (:...tenantIds))', { facilityIds, tenantIds })
			.orderBy('visit.tanggal_kunjungan', 'DESC')
			.getMany();
		if (!patient) return [];
		return records.map((record) => this.toEntity(record));
	}

	async findByTenant(tenantId: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity[]> {
		if (!user.memberships.some((item) => item.tenant_id === tenantId)) throw new ForbiddenException('Facility access denied.');
		const records = await this.visitRepository.find({ where: { tenant_id: tenantId }, order: { tanggal_kunjungan: 'DESC' } });
		return records.map((record) => this.toEntity(record));
	}

	async update(id: string, data: UpdateIstoriaKlinisDto, user: AuthenticatedUser): Promise<IstoriaKlinisEntity> {
		const record = await this.visitRepository.findOne({ where: { kunjungan_id: id } });
		if (!record) throw new NotFoundException('Clinical visit not found.');
		const allowedTenants = user.memberships.map((item) => item.tenant_id);
		const allowedFacilities = user.memberships.map((item) => item.facility_id);
		if (!allowedTenants.includes(record.tenant_id) && !allowedFacilities.includes(record.facility_id ?? '')) {
			throw new ForbiddenException('Clinical visit access denied.');
		}
		if (data.visit_date !== undefined) record.tanggal_kunjungan = new Date(data.visit_date);
		if (data.keluhan_subjektif !== undefined) record.keluhan_subjektif = data.keluhan_subjektif;
		if (data.pemeriksaan_objektif !== undefined) record.pemeriksaan_objektif = data.pemeriksaan_objektif ?? null;
		if (data.analisis_asesmen !== undefined) record.analisis_asesmen = data.analisis_asesmen ?? null;
		if (data.rencana_tindakan !== undefined) record.rencana_tindakan = data.rencana_tindakan ?? null;
		if (data.kode_icd10 !== undefined) record.kode_icd10 = data.kode_icd10;
		if (data.nama_penyakit_lokal !== undefined) record.nama_penyakit_lokal = data.nama_penyakit_lokal ?? null;
		record.updated_at = new Date();
		return this.toEntity(await this.visitRepository.save(record));
	}

	private toEntity(record: ClinicalVisitRecord): IstoriaKlinisEntity {
		return {
			kunjungan_id: record.kunjungan_id,
			pasien_id: record.pasien_id,
			facility_id: record.facility_id ?? undefined,
			tenant_id: record.tenant_id,
			staf_id: record.staf_id ?? undefined,
			tanggal_kunjungan: record.tanggal_kunjungan,
			keluhan_subjektif: record.keluhan_subjektif,
			pemeriksaan_objektif: record.pemeriksaan_objektif ?? undefined,
			analisis_asesmen: record.analisis_asesmen ?? undefined,
			rencana_tindakan: record.rencana_tindakan ?? undefined,
			kode_icd10: record.kode_icd10,
			nama_penyakit_lokal: record.nama_penyakit_lokal ?? undefined,
			status_sinkronisasi: record.status_sinkronisasi,
			created_at: record.created_at,
			updated_at: record.updated_at,
		};
	}
}
