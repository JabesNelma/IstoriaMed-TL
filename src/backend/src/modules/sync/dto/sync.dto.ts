import { Type } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsObject, IsOptional, IsString, IsUUID, ValidateNested } from 'class-validator';

import { CreatePatientDto } from '../../pasien/dto/patient.dto';
import { CreateIstoriaKlinisDto } from '../../istoria_klinis/dto/create-istoria-klinis.dto';
import { CreatePrescriptionDto } from '../../prescription/dto/prescription.dto';

export const SYNC_ENTITY_TYPES = ['PATIENT', 'CLINICAL_VISIT', 'PRESCRIPTION'] as const;
export const SYNC_OPERATION_TYPES = ['CREATE'] as const;

export type SyncEntityType = (typeof SYNC_ENTITY_TYPES)[number];
export type SyncOperationType = (typeof SYNC_OPERATION_TYPES)[number];

/**
 * The server always derives ownership from the authenticated user
 * (user -> membership -> facility -> tenant -> staff).
 * A client may never submit these fields.
 *
 * Reserved entity identifiers such as `patient_id`, `kunjungan_id` and
 * `prescription_id` are deliberately NOT protected: following the Phase 6
 * convention the device reserves them before going offline and the server adopts
 * them verbatim. Only ownership and server bookkeeping are protected.
 */
export const PROTECTED_PAYLOAD_FIELDS = [
  'facility_id',
  'tenant_id',
  'staf_id',
  'staff_id',
  'user_id',
  'membership_id',
  'status_sinkronisasi',
  'medical_record_number',
  'tanggal_terdaftar',
  'prescribed_by_staff_id',
  'created_at',
  'updated_at',
  'processed_at',
] as const;

/** Offline payload for a patient CREATE operation. */
export class SyncPatientPayloadDto extends CreatePatientDto {
  @IsUUID()
  patient_id!: string;
}

/** Offline payload for a clinical visit CREATE operation. */
export class SyncClinicalVisitPayloadDto extends CreateIstoriaKlinisDto {
  @IsUUID()
  kunjungan_id!: string;
}

/**
 * Offline payload for a prescription CREATE operation.
 *
 * `prescription_id` is the canonical identifier the device reserved before going
 * offline; the server adopts it verbatim so no identifier mapping is needed.
 * Ownership (`prescribed_by_staff_id`, `facility_id`, `tenant_id`) is derived by
 * the server exactly like it is for the online endpoint.
 */
export class SyncPrescriptionPayloadDto extends CreatePrescriptionDto {
  @IsUUID()
  prescription_id!: string;
}

export class SyncRecordDto {
  @IsUUID()
  operation_id!: string;

  @IsEnum(SYNC_ENTITY_TYPES)
  entity_type!: SyncEntityType;

  @IsEnum(SYNC_OPERATION_TYPES)
  operation_type!: SyncOperationType;

  /** Canonical identifier the client reserved for the entity before going offline. */
  @IsUUID()
  entity_id!: string;

  @IsObject()
  @IsNotEmpty()
  payload!: Record<string, unknown>;
}

export class SyncOperationResponseDto {
  @IsUUID()
  operation_id!: string;

  @IsEnum(['PENDING', 'SYNCING', 'SYNCED', 'FAILED'])
  status!: 'PENDING' | 'SYNCING' | 'SYNCED' | 'FAILED';

  @IsOptional()
  @IsUUID()
  entity_id?: string;

  @IsOptional()
  @IsString()
  message?: string;
}

export class SyncOperationRequestDto {
  @ValidateNested()
  @Type(() => SyncRecordDto)
  operation!: SyncRecordDto;
}
