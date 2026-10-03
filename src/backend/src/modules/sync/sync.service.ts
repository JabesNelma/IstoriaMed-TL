import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { randomUUID } from 'node:crypto';
import { DataSource, EntityManager, ObjectLiteral, QueryFailedError, Repository } from 'typeorm';

import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { PatientRecord } from '../../database/entities/patient.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { SyncOperationRecord } from '../../database/entities/sync-operation.record';
import { AuthenticatedMembership, AuthenticatedUser } from '../auth/auth.types';
import { PrescriptionService } from '../prescription/prescription.service';
import {
  PROTECTED_PAYLOAD_FIELDS,
  SyncClinicalVisitPayloadDto,
  SyncPatientPayloadDto,
  SyncPrescriptionPayloadDto,
  SyncRecordDto,
} from './dto/sync.dto';

export type SyncOutcomeStatus = 'SYNCED' | 'FAILED' | 'PENDING';

export interface SyncOutcome {
  operation_id: string;
  status: SyncOutcomeStatus;
  entity_id?: string;
  message?: string;
  entity?: Record<string, unknown>;
}

interface ExecutedEntity {
  entity_id: string;
  entity?: Record<string, unknown>;
}

/** Unique violation: PostgreSQL `23505`, MySQL/TiDB `ER_DUP_ENTRY` (1062). */
function isUniqueViolation(error: unknown): boolean {
  const code = driverErrorCode(error);
  return code === '23505' || code === 'ER_DUP_ENTRY';
}

/** Missing parent row: PostgreSQL `23503`, MySQL/TiDB `ER_NO_REFERENCED_ROW_2` (1452). */
function isForeignKeyViolation(error: unknown): boolean {
  const code = driverErrorCode(error);
  return code === '23503' || code === 'ER_NO_REFERENCED_ROW_2';
}

function driverErrorCode(error: unknown): string | undefined {
  if (!(error instanceof QueryFailedError)) return undefined;
  const code = (error as QueryFailedError & { driverError?: { code?: string | number } }).driverError?.code;
  return code === undefined ? undefined : String(code);
}

function errorMessage(error: unknown): string {
  if (error instanceof HttpException) {
    const response = error.getResponse();
    if (typeof response === 'string') return response;
    const message = (response as { message?: unknown }).message;
    if (Array.isArray(message)) return message.join('; ');
    if (typeof message === 'string') return message;
  }
  if (error instanceof Error) return error.message;
  return 'Unknown sync error';
}

@Injectable()
export class SyncService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly prescriptionService: PrescriptionService,
    @InjectRepository(SyncOperationRecord)
    private readonly syncOperationRepository: Repository<SyncOperationRecord>,
  ) {}

  /**
   * Idempotent offline operation intake.
   *
   * Guarantees:
   * - the `sync_operations.operation_id` primary key is the database-level
   *   uniqueness boundary, so a replayed operation can never create a second
   *   medical record;
   * - idempotency claim, entity insert and operation result are committed in a
   *   single transaction, so an operation is never marked SYNCED unless the
   *   entity is really committed;
   * - facility, tenant and staff ownership are always derived from the
   *   authenticated user, never from the payload.
   */
  async processOperation(data: SyncRecordDto, user: AuthenticatedUser): Promise<SyncOutcome> {
    const terminal = await this.replayTerminalOutcome(data.operation_id);
    if (terminal) return terminal;

    await this.claimOperation(data);

    try {
      return await this.dataSource.transaction(async (manager) => this.runOperation(manager, data, user));
    } catch (error) {
      await this.recordFailure(data, error);
      if (this.isPermanentFailure(error)) {
        return { operation_id: data.operation_id, status: 'FAILED', entity_id: data.entity_id, message: errorMessage(error) };
      }
      throw error;
    }
  }

  /** Returns the stored outcome when the operation already reached a terminal state. */
  private async replayTerminalOutcome(operationId: string): Promise<SyncOutcome | undefined> {
    const existing = await this.syncOperationRepository.findOne({ where: { operation_id: operationId } });
    if (!existing) return undefined;
    if (existing.status !== 'SYNCED' && existing.status !== 'FAILED') return undefined;
    return {
      operation_id: existing.operation_id,
      status: existing.status,
      entity_id: existing.entity_id ?? undefined,
      message: existing.last_error ?? undefined,
    };
  }

  /**
   * Atomically registers the operation. The no-op self assignment on a duplicate
   * primary key is the database-level race guard: two concurrent replays of the
   * same operation_id can never both create the claim row, and any other failure
   * (a rejected payload, a bad column value) still surfaces instead of being
   * silently swallowed the way `INSERT IGNORE` would.
   */
  private async claimOperation(data: SyncRecordDto): Promise<void> {
    const now = new Date();
    await this.syncOperationRepository.query(
      `INSERT INTO sync_operations
         (operation_id, entity_type, entity_id, operation_type, status, retry_count, payload, last_error, created_at, updated_at)
       VALUES (?, ?, ?, ?, 'PENDING', 0, ?, NULL, ?, ?)
       ON DUPLICATE KEY UPDATE operation_id = operation_id`,
      [data.operation_id, data.entity_type, data.entity_id, data.operation_type, JSON.stringify(data.payload ?? {}), now, now],
    );
  }

  private async runOperation(manager: EntityManager, data: SyncRecordDto, user: AuthenticatedUser): Promise<SyncOutcome> {
    const repository = manager.getRepository(SyncOperationRecord);
    // Row lock serialises concurrent replays of the same operation_id:
    // the loser of the race observes the committed SYNCED state and does not
    // execute the entity insert twice.
    const operation = await repository.findOne({
      where: { operation_id: data.operation_id },
      lock: { mode: 'pessimistic_write' },
    });
    if (!operation) throw new NotFoundException('Sync operation record is missing.');

    if (operation.status === 'SYNCED' || operation.status === 'FAILED') {
      return {
        operation_id: operation.operation_id,
        status: operation.status,
        entity_id: operation.entity_id ?? undefined,
        message: operation.last_error ?? undefined,
      };
    }

    const now = new Date();
    operation.status = 'SYNCING';
    operation.entity_type = data.entity_type;
    operation.entity_id = data.entity_id;
    operation.operation_type = data.operation_type;
    operation.retry_count = (operation.retry_count ?? 0) + 1;
    operation.payload = data.payload ?? {};
    operation.updated_at = now;
    await repository.save(operation);

    const executed = await this.execute(manager, data, user);

    operation.status = 'SYNCED';
    operation.entity_id = executed.entity_id;
    operation.last_error = null;
    operation.processed_at = new Date();
    operation.updated_at = new Date();
    await repository.save(operation);

    return {
      operation_id: operation.operation_id,
      status: 'SYNCED',
      entity_id: executed.entity_id,
      entity: executed.entity,
    };
  }

  private async execute(manager: EntityManager, data: SyncRecordDto, user: AuthenticatedUser): Promise<ExecutedEntity> {
    if (data.entity_type === 'PATIENT') return this.executePatient(manager, data, user);
    if (data.entity_type === 'CLINICAL_VISIT') return this.executeClinicalVisit(manager, data, user);
    if (data.entity_type === 'PRESCRIPTION') return this.executePrescription(manager, data, user);
    throw new BadRequestException('Unsupported entity type.');
  }

  /**
   * Reuses the online prescription write path so offline and online prescriptions
   * share one authorization implementation and one transactional boundary.
   *
   * The client side queue orders this operation after the clinical visit it
   * belongs to, so by the time it is processed the visit already exists on the
   * server. If it does not, the operation fails permanently rather than creating
   * an orphan prescription.
   */
  private async executePrescription(manager: EntityManager, data: SyncRecordDto, user: AuthenticatedUser): Promise<ExecutedEntity> {
    const payload = await this.parsePayload(SyncPrescriptionPayloadDto, data);
    this.resolveMembership(user);

    const prescription = await this.prescriptionService.createWithinTransaction(
      manager,
      payload,
      user,
      payload.prescription_id,
    );

    return {
      entity_id: prescription.prescription_id,
      entity: {
        visit_id: prescription.visit_id,
        prescribed_by_staff_id: prescription.prescribed_by_staff_id,
        facility_id: prescription.facility_id,
        tenant_id: prescription.tenant_id,
        prescribed_at: prescription.prescribed_at,
        item_count: prescription.items.length,
      },
    };
  }

  private resolveMembership(user: AuthenticatedUser): AuthenticatedMembership {
    const memberships = user.memberships.filter((item) => item.role !== 'SUPER_ADMIN' && item.role !== 'SYSTEM_ADMIN');
    const membership =
      memberships.length === 1 ? memberships[0] : user.memberships.length === 1 ? user.memberships[0] : undefined;
    if (!membership) {
      throw new ForbiddenException('An unambiguous active facility membership is required to synchronize offline data.');
    }
    return membership;
  }

  private async executePatient(manager: EntityManager, data: SyncRecordDto, user: AuthenticatedUser): Promise<ExecutedEntity> {
    const payload = await this.parsePayload(SyncPatientPayloadDto, data);
    const membership = this.resolveMembership(user);
    const now = new Date();
    const repository = manager.getRepository(PatientRecord);
    const patient = repository.create({
      patient_id: payload.patient_id,
      medical_record_number: `MRN-${randomUUID()}`,
      facility_id: membership.facility_id,
      no_ktp: payload.no_ktp ?? null,
      nama_lengkap: payload.nama_lengkap,
      tanggal_lahir: payload.tanggal_lahir,
      tempat_lahir: payload.tempat_lahir,
      jenis_kelamin: payload.jenis_kelamin,
      municipality: payload.municipality ?? null,
      administrative_post: payload.administrative_post ?? null,
      village: payload.village ?? null,
      fingerprint_hash: payload.fingerprint_hash ?? null,
      tanggal_terdaftar: now,
      updated_at: now,
    });

    const saved = await this.saveEntity(repository, patient, 'A patient with this identifier already exists on the server.');
    return {
      entity_id: saved.patient_id,
      entity: { medical_record_number: saved.medical_record_number, facility_id: saved.facility_id },
    };
  }

  private async executeClinicalVisit(manager: EntityManager, data: SyncRecordDto, user: AuthenticatedUser): Promise<ExecutedEntity> {
    const payload = await this.parsePayload(SyncClinicalVisitPayloadDto, data);
    const membership = this.resolveMembership(user);

    const patient = await manager.getRepository(PatientRecord).findOne({ where: { patient_id: payload.pasien_id } });
    if (!patient) {
      throw new NotFoundException('Patient not found. Synchronize the patient operation before its clinical visit.');
    }
    if (patient.facility_id && patient.facility_id !== membership.facility_id) {
      throw new ForbiddenException('Patient outside the authorized facility.');
    }

    const staff = await manager.getRepository(StaffRecord).findOne({
      where: { user_id: user.user_id, facility_id: membership.facility_id, verification_status: 'Approved' },
    });
    if (!staff) throw new ForbiddenException('A verified staff profile is required for clinical visits.');

    const now = new Date();
    const repository = manager.getRepository(ClinicalVisitRecord);
    const visit = repository.create({
      kunjungan_id: payload.kunjungan_id,
      pasien_id: payload.pasien_id,
      facility_id: membership.facility_id,
      tenant_id: membership.tenant_id,
      staf_id: staff.staff_id,
      tanggal_kunjungan: new Date(payload.visit_date ?? now),
      keluhan_subjektif: payload.keluhan_subjektif,
      pemeriksaan_objektif: payload.pemeriksaan_objektif ?? null,
      analisis_asesmen: payload.analisis_asesmen ?? null,
      rencana_tindakan: payload.rencana_tindakan ?? null,
      kode_icd10: payload.kode_icd10,
      nama_penyakit_lokal: payload.nama_penyakit_lokal ?? null,
      status_sinkronisasi: 'Synced',
      created_at: now,
      updated_at: now,
    });

    const saved = await this.saveEntity(repository, visit, 'A clinical visit with this identifier already exists on the server.');
    return {
      entity_id: saved.kunjungan_id,
      entity: {
        tenant_id: saved.tenant_id,
        facility_id: saved.facility_id,
        staf_id: saved.staf_id,
        tanggal_kunjungan: saved.tanggal_kunjungan,
        status_sinkronisasi: saved.status_sinkronisasi,
      },
    };
  }

  private async saveEntity<T extends ObjectLiteral>(
    repository: Repository<T>,
    entity: T,
    conflictMessage: string,
  ): Promise<T> {
    try {
      return await repository.save(entity);
    } catch (error) {
      if (isUniqueViolation(error)) throw new ConflictException(conflictMessage);
      if (isForeignKeyViolation(error)) throw new NotFoundException('Referenced record does not exist on the server.');
      throw error;
    }
  }

  /**
   * Validates the offline payload with the same rules the online endpoints use
   * and refuses any attempt to dictate ownership.
   */
  private async parsePayload<T extends object>(type: new () => T, data: SyncRecordDto): Promise<T> {
    const payload = data.payload ?? {};
    const protectedField = PROTECTED_PAYLOAD_FIELDS.find((field) => Object.prototype.hasOwnProperty.call(payload, field));
    if (protectedField) {
      throw new BadRequestException(
        `Payload may not contain server owned field "${protectedField}". Ownership is derived from the authenticated user.`,
      );
    }

    const instance = plainToInstance(type, payload, { excludeExtraneousValues: false });
    const errors = await validate(instance, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length) {
      const details = errors
        .flatMap((error) => (error.constraints ? Object.values(error.constraints) : [`${error.property} is invalid`]))
        .join('; ');
      throw new BadRequestException(details);
    }
    return instance;
  }

  private isPermanentFailure(error: unknown): boolean {
    return (
      error instanceof BadRequestException ||
      error instanceof ForbiddenException ||
      error instanceof NotFoundException ||
      error instanceof ConflictException ||
      error instanceof UnauthorizedException
    );
  }

  /**
   * Records the outcome of a failed attempt in its own transaction so a
   * rollback of the business transaction can never leave a falsely
   * successful operation, and a committed success is never downgraded.
   */
  private async recordFailure(data: SyncRecordDto, error: unknown): Promise<void> {
    const permanent = this.isPermanentFailure(error);
    const message = errorMessage(error);
    await this.dataSource.transaction(async (manager) => {
      const repository = manager.getRepository(SyncOperationRecord);
      const operation = await repository.findOne({
        where: { operation_id: data.operation_id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!operation) return;
      if (operation.status === 'SYNCED') return;
      operation.status = permanent ? 'FAILED' : 'PENDING';
      operation.last_error = message;
      operation.processed_at = permanent ? new Date() : null;
      operation.updated_at = new Date();
      await repository.save(operation);
    });
  }
}
