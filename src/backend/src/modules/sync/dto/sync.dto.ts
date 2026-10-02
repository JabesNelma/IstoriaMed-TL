import { Type } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsObject, IsOptional, IsString, IsUUID, ValidateNested } from 'class-validator';

import { CreatePatientDto } from '../../pasien/dto/patient.dto';
import { CreateIstoriaKlinisDto } from '../../istoria_klinis/dto/create-istoria-klinis.dto';

export const SYNC_ENTITY_TYPES = ['PATIENT', 'CLINICAL_VISIT'] as const;
export const SYNC_OPERATION_TYPES = ['CREATE'] as const;

export type SyncEntityType = (typeof SYNC_ENTITY_TYPES)[number];
export type SyncOperationType = (typeof SYNC_OPERATION_TYPES)[number];

/**
 * The server always derives ownership from the authenticated user
 * (user -> membership -> facility -> tenant -> staff).
 * A client may never submit these fields.
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
