import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { PatientRecord } from '../../database/entities/patient.record';
import { AuthenticatedUser } from '../auth/auth.types';
import { PasienEntity } from './pasien.entity';
import { CreatePatientDto, SearchPatientDto, UpdatePatientDto } from './dto/patient.dto';

/** Unique violation: PostgreSQL `23505`, MySQL/TiDB `ER_DUP_ENTRY` (1062). */
function isUniqueViolation(error: unknown): boolean {
	if (!(error instanceof QueryFailedError)) return false;
	const code = (error as QueryFailedError & { driverError?: { code?: string | number } }).driverError?.code;
	return code === '23505' || code === 'ER_DUP_ENTRY';
}

@Injectable()
export class PasienService {
	constructor(
		@InjectRepository(PatientRecord)
		private readonly patientRepository: Repository<PatientRecord>,
	) {}

	async create(
		data: CreatePatientDto,
		user: AuthenticatedUser,
	): Promise<PasienEntity> {
		const now = new Date();
		const memberships = user.memberships.filter((item) => item.role !== 'SUPER_ADMIN' && item.role !== 'SYSTEM_ADMIN');
		const membership = memberships.length === 1 ? memberships[0] : user.memberships.length === 1 ? user.memberships[0] : undefined;
		if (!membership) throw new ForbiddenException('An active facility membership is required.');
		const record = this.patientRepository.create({
			patient_id: randomUUID(),
			medical_record_number: `MRN-${randomUUID()}`,
			facility_id: membership.facility_id,
			no_ktp: data.no_ktp ?? null,
			nama_lengkap: data.nama_lengkap,
			tanggal_lahir: data.tanggal_lahir,
			tempat_lahir: data.tempat_lahir,
			jenis_kelamin: data.jenis_kelamin,
			municipality: data.municipality ?? null,
			administrative_post: data.administrative_post ?? null,
			village: data.village ?? null,
			fingerprint_hash: data.fingerprint_hash ?? null,
			tanggal_terdaftar: now,
			updated_at: now,
		});

		try {
			return this.toEntity(await this.patientRepository.save(record));
		} catch (error) {
			if (isUniqueViolation(error)) {
				throw new ConflictException("KTP ne'e rejistradu ona!");
			}
			throw error;
		}
	}

	async findAll(user: AuthenticatedUser, search: SearchPatientDto = {}): Promise<PasienEntity[]> {
		const isGlobalAdmin = user.memberships.some((item) => item.role === 'SUPER_ADMIN' || item.role === 'SYSTEM_ADMIN');
		const query = this.patientRepository.createQueryBuilder('patient');
		if (!isGlobalAdmin) {
			const facilityIds = user.memberships.map((item) => item.facility_id);
			if (!facilityIds.length) return [];
			query.andWhere('patient.facility_id IN (:...facilityIds)', { facilityIds });
		}
			if (search.q) {
				// `LOWER(...) LIKE LOWER(...)` is the MySQL/TiDB equivalent of
				// PostgreSQL's `ILIKE`: the comparison is case insensitive whatever
				// collation the column was created with.
				query.andWhere(
					'(LOWER(patient.medical_record_number) LIKE LOWER(:query) OR LOWER(patient.nama_lengkap) LIKE LOWER(:query) OR LOWER(patient.no_ktp) LIKE LOWER(:query))',
					{ query: `%${search.q}%` },
				);
			}
		const records = await query.orderBy('patient.tanggal_terdaftar', 'DESC').take(50).getMany();
		return records.map((record) => this.toEntity(record));
	}

	async findOne(id: string): Promise<PasienEntity | undefined> {
		const record = await this.patientRepository.findOne({ where: { patient_id: id } });
		return record ? this.toEntity(record) : undefined;
	}

	async findOneForUser(id: string, user: AuthenticatedUser): Promise<PasienEntity> {
		const isGlobalAdmin = user.memberships.some((item) => item.role === 'SUPER_ADMIN' || item.role === 'SYSTEM_ADMIN');
		const query = this.patientRepository.createQueryBuilder('patient').where('patient.patient_id = :id', { id });
		if (!isGlobalAdmin) {
			const facilityIds = user.memberships.map((item) => item.facility_id);
			if (!facilityIds.length) throw new NotFoundException('Pasiente la hetan.');
			query.andWhere('patient.facility_id IN (:...facilityIds)', { facilityIds });
		}
		const record = await query.getOne();
		if (!record) throw new NotFoundException('Pasiente la hetan.');
		return this.toEntity(record);
	}

	async update(id: string, data: UpdatePatientDto, user: AuthenticatedUser): Promise<PasienEntity> {
		const isGlobalAdmin = user.memberships.some((item) => item.role === 'SUPER_ADMIN' || item.role === 'SYSTEM_ADMIN');
		const query = this.patientRepository.createQueryBuilder('patient').where('patient.patient_id = :id', { id });
		if (!isGlobalAdmin) {
			const facilityIds = user.memberships.map((item) => item.facility_id);
			if (!facilityIds.length) throw new NotFoundException('Pasiente la hetan.');
			query.andWhere('patient.facility_id IN (:...facilityIds)', { facilityIds });
		}
		const record = await query.getOne();
		if (!record) throw new NotFoundException('Pasiente la hetan.');
		if (data.no_ktp !== undefined) record.no_ktp = data.no_ktp ?? null;
		if (data.nama_lengkap !== undefined) record.nama_lengkap = data.nama_lengkap;
		if (data.tanggal_lahir !== undefined) record.tanggal_lahir = data.tanggal_lahir;
		if (data.tempat_lahir !== undefined) record.tempat_lahir = data.tempat_lahir;
		if (data.jenis_kelamin !== undefined) record.jenis_kelamin = data.jenis_kelamin;
		if (data.municipality !== undefined) record.municipality = data.municipality;
		if (data.administrative_post !== undefined) record.administrative_post = data.administrative_post;
		if (data.village !== undefined) record.village = data.village;
		record.updated_at = new Date();
		try {
			return this.toEntity(await this.patientRepository.save(record));
		} catch (error) {
			if (isUniqueViolation(error)) {
				throw new ConflictException("KTP ne'e rejistradu ona!");
			}
			throw error;
		}
	}

	private toEntity(record: PatientRecord): PasienEntity {
		return {
			user_id: record.patient_id,
			medical_record_number: record.medical_record_number,
			facility_id: record.facility_id ?? undefined,
			no_ktp: record.no_ktp,
			nama_lengkap: record.nama_lengkap,
			tanggal_lahir: new Date(record.tanggal_lahir),
			tempat_lahir: record.tempat_lahir,
			jenis_kelamin: record.jenis_kelamin,
			municipality: record.municipality ?? undefined,
			administrative_post: record.administrative_post ?? undefined,
			village: record.village ?? undefined,
			fingerprint_hash: record.fingerprint_hash ?? undefined,
			tanggal_terdaftar: record.tanggal_terdaftar,
			updated_at: record.updated_at,
		};
	}
}
