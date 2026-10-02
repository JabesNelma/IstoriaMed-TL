import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/**
 * Query parameters always arrive as strings, so `?include_inactive=false`
 * reaches the validation pipe as the string "false" and would fail
 * `@IsBoolean()`. Only the explicit boolean spellings are accepted; anything
 * else is rejected instead of being silently coerced.
 */
const toBoolean = ({ value }: { value: unknown }): unknown => {
  if (value === undefined || value === null) return value;
  if (typeof value === 'boolean') return value;
  if (value === 'true') return true;
  if (value === 'false') return false;
  return value;
};

/** One prescribed drug line as supplied by the authorized medical professional. */
export class CreatePrescriptionItemDto {
  @IsString()
  @IsUUID()
  @Length(1, 100)
  medication_id!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'dose must not be blank' })
  dose!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'frequency must not be blank' })
  frequency!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  route?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  duration?: string;

  @IsInt()
  @Min(1)
  @Max(100000)
  quantity!: number;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 500)
  instructions?: string;
}

/**
 * Create prescription request.
 *
 * Only client controlled clinical content is accepted here. `prescribed_by_staff_id`,
 * `facility_id` and `tenant_id` are intentionally absent: they are server owned
 * and are derived from the authenticated user and the owning clinical visit.
 */
export class CreatePrescriptionDto {
  @IsString()
  @IsUUID()
  @Length(1, 100)
  visit_id!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 5000)
  notes?: string;

  /**
   * When the prescription was written. Optional and client controlled because an
   * offline prescription keeps the time the clinician authored it; the server
   * falls back to the moment it receives the record.
   */
  @IsOptional()
  @IsDateString()
  prescribed_at?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => CreatePrescriptionItemDto)
  items!: CreatePrescriptionItemDto[];
}

/** Medication catalog creation. Restricted to administrative roles. */
export class CreateMedicationDto {
  @Transform(trim)
  @IsString()
  @Length(1, 150)
  @Matches(/\S/, { message: 'name must not be blank' })
  name!: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 150)
  generic_name?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  form?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  strength?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  unit?: string;

  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

/** Medication catalog search. */
export class SearchMedicationDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 150)
  q?: string;

  @IsOptional()
  @Transform(toBoolean)
  @IsBoolean()
  include_inactive?: boolean;
}