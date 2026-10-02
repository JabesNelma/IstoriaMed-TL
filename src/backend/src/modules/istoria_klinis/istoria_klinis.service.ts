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

/** One facility membership as an exact (facility, tenant) authorization pair. */
interface MembershipPair {
	facilityId: string;
	tenantId: string;
}

interface VisitScope {
	sql: string;
	parameters: Record<string, string | string[]>;
}

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
		const scope = this.visitScope('visit', user);
		if (!scope) return [];
		const records = await this.visitRepository.createQueryBuilder('visit')
			.where(scope.sql, scope.parameters)
			.orderBy('visit.tanggal_kunjungan', 'DESC')
			.getMany();
		return records.map((record) => this.toEntity(record));
	}

	async findOne(id: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity> {
		const scope = this.visitScope('visit', user);
		if (!scope) throw new NotFoundException('Clinical visit not found.');
		const record = await this.visitRepository.createQueryBuilder('visit')
			.where('visit.kunjungan_id = :id', { id })
			.andWhere(scope.sql, scope.parameters)
			.getOne();
		if (!record) throw new NotFoundException('Clinical visit not found.');
		return this.toEntity(record);
	}

	async findByPatient(pasienId: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity[]> {
		const patient = await this.pasienService.findOneForUser(pasienId, user);
		if (!patient) return [];
		const scope = this.visitScope('visit', user);
		if (!scope) return [];
		const records = await this.visitRepository.createQueryBuilder('visit')
			.where('visit.pasien_id = :pasienId', { pasienId })
			.andWhere(scope.sql, scope.parameters)
			.orderBy('visit.tanggal_kunjungan', 'DESC')
			.getMany();
		return records.map((record) => this.toEntity(record));
	}

	async findByTenant(tenantId: string, user: AuthenticatedUser): Promise<IstoriaKlinisEntity[]> {
		if (!user.memberships.some((item) => item.tenant_id === tenantId)) throw new ForbiddenException('Facility access denied.');
		const scope = this.visitScope('visit', user);
		if (!scope) return [];
		const records = await this.visitRepository.createQueryBuilder('visit')
			.where('visit.tenant_id = :tenantId', { tenantId })
			.andWhere(scope.sql, scope.parameters)
			.orderBy('visit.tanggal_kunjungan', 'DESC')
			.getMany();
		return records.map((record) => this.toEntity(record));
	}

	async update(id: string, data: UpdateIstoriaKlinisDto, user: AuthenticatedUser): Promise<IstoriaKlinisEntity> {
		const record = await this.visitRepository.findOne({ where: { kunjungan_id: id } });
		if (!record) throw new NotFoundException('Clinical visit not found.');
		// Exact pair check. The previous deny condition used
		// `!tenantMatches && !facilityMatches`, which permits the write when
		// either value matches and therefore allowed a cross facility edit of
		// another tenant's clinical record.
		if (!this.canAccessVisit(record, user)) {
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

	/**
	 * Builds an exact (facility, tenant) pair predicate.
	 *
	 * The previous implementation matched `facility_id IN (...) OR
	 * tenant_id IN (...)`, which is not pair safe. A clinical visit whose
	 * `tenant_id` column disagrees with the tenant that actually owns its
	 * facility was then disclosed to every member of that tenant and could also
	 * be modified by them. Legacy visits that predate facility assignment have
	 * no facility, so they stay visible to their own tenant only.
	 */
	private visitScope(alias: string, user: AuthenticatedUser): VisitScope | undefined {
		const pairs: MembershipPair[] = [
			...new Map(
				user.memberships.map((membership) => [
					`${membership.facility_id}|${membership.tenant_id}`,
					{ facilityId: membership.facility_id, tenantId: membership.tenant_id },
				]),
			).values(),
		];
		const legacyTenantIds = [...new Set(user.memberships.map((membership) => membership.tenant_id))];

		const clauses: string[] = [];
		const parameters: Record<string, string | string[]> = {};
		pairs.forEach((pair, index) => {
			clauses.push(`(${alias}.facility_id = :facilityId${index} AND ${alias}.tenant_id = :tenantId${index})`);
			parameters[`facilityId${index}`] = pair.facilityId;
			parameters[`tenantId${index}`] = pair.tenantId;
		});
		if (legacyTenantIds.length) {
			clauses.push(`(${alias}.facility_id IS NULL AND ${alias}.tenant_id IN (:...legacyTenantIds))`);
			parameters['legacyTenantIds'] = legacyTenantIds;
		}
		// The whole disjunction is wrapped in parentheses. Without them SQL
		// precedence binds `AND` before `OR`, so a row matching any later branch
		// would escape the caller's primary key filter and the `:id` lookup would
		// silently return an arbitrary in-scope record instead of 404.
		return clauses.length ? { sql: `(${clauses.join(' OR ')})`, parameters } : undefined;
	}

	/** The same pair rule as `visitScope`, applied to one already loaded row. */
	private canAccessVisit(record: ClinicalVisitRecord, user: AuthenticatedUser): boolean {
		if (!record.facility_id) {
			return user.memberships.some((membership) => membership.tenant_id === record.tenant_id);
		}
		return user.memberships.some(
			(membership) =>
				membership.facility_id === record.facility_id && membership.tenant_id === record.tenant_id,
		);
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
