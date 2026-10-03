import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, Length, Matches } from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/**
 * Query parameters always arrive as strings, so only the explicit boolean
 * spellings are accepted; anything else is rejected instead of being silently
 * coerced. Same rule as the medication catalog search.
 */
const toBoolean = ({ value }: { value: unknown }): unknown => {
  if (value === undefined || value === null) return value;
  if (typeof value === 'boolean') return value;
  if (value === 'true') return true;
  if (value === 'false') return false;
  return value;
};

/**
 * The one tenant identifier format: a lowercase slug. It must match the schema
 * CHECK `tenants_tenant_id_format` and the migration audit exactly, otherwise a
 * tenant could be created that no facility can reference.
 */
export const TENANT_ID_PATTERN = /^[a-z0-9][a-z0-9._-]*$/;

/** Create tenant request. Restricted to the administrative roles. */
export class CreateTenantDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value))
  @IsString()
  @Length(1, 100)
  @Matches(TENANT_ID_PATTERN, {
    message:
      'tenant_id must be a lowercase slug: start with a letter or digit, then only letters, digits, dots, dashes or underscores',
  })
  tenant_id!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 150)
  @Matches(/\S/, { message: 'name must not be blank' })
  name!: string;
}

/** Update tenant request. `tenant_id` itself is immutable once created. */
export class UpdateTenantDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 150)
  @Matches(/\S/, { message: 'name must not be blank' })
  name?: string;

  @IsOptional()
  @Transform(toBoolean)
  @IsBoolean()
  is_active?: boolean;
}

/** Tenant list search. */
export class SearchTenantDto {
  @IsOptional()
  @Transform(toBoolean)
  @IsBoolean()
  include_inactive?: boolean;
}
