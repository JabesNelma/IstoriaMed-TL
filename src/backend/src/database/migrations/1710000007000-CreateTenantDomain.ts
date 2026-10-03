import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Phase 9 - Tenant domain foundation.
 *
 * Closes the Phase 8 blocker: tenant identity is no longer a free text label
 * anchored only on `facilities.tenant_id`. An authoritative `tenants` table now
 * exists and every `tenant_id` column references it.
 *
 * The primary key is deliberately the natural key `tenant_id varchar(100)`,
 * the same type and value space as the columns that already carry tenant
 * identity. That keeps the Phase 8 composite pair constraint
 * `uq_facilities_facility_tenant (facility_id, tenant_id)` and the child
 * composite foreign keys valid without touching a single column type, and the
 * pair based authorization layer keeps working unchanged.
 *
 * Existing rows are backfilled: every distinct `facilities.tenant_id` becomes a
 * tenant row whose name starts as the identifier itself and can be renamed
 * through the administration API. The audit below fails loudly and
 * descriptively when pre-existing data cannot satisfy the format, instead of
 * letting PostgreSQL emit an opaque constraint violation halfway through.
 *
 * `ON DELETE RESTRICT` everywhere, matching every foreign key in this project:
 * a tenant that still owns facilities, clinical visits or prescriptions cannot
 * be erased.
 *
 * No previously applied migration is edited.
 */

/** The one tenant identifier format, enforced at the schema, DTO and audit level. */
export const TENANT_ID_FORMAT = '^[a-z0-9][a-z0-9._-]*$';

export class CreateTenantDomain1710000007000 implements MigrationInterface {
  name = 'CreateTenantDomain1710000007000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // Audit before writing anything: every tenant identifier that is about to
    // gain a foreign key must already satisfy the format, otherwise the new
    // constraints would reject data the database currently holds.
    const offenders: Array<{ table_name: string; tenant_id: string }> = await queryRunner.query(`
      SELECT 'facilities' AS table_name, tenant_id FROM facilities
        WHERE tenant_id IS NULL OR NOT (tenant_id REGEXP '${TENANT_ID_FORMAT}')
      UNION ALL
      SELECT 'clinical_visits', tenant_id FROM clinical_visits
        WHERE tenant_id IS NULL OR NOT (tenant_id REGEXP '${TENANT_ID_FORMAT}')
      UNION ALL
      SELECT 'prescriptions', tenant_id FROM prescriptions
        WHERE tenant_id IS NULL OR NOT (tenant_id REGEXP '${TENANT_ID_FORMAT}')
      LIMIT 50
    `);
    if (offenders.length) {
      const summary = offenders.map((row) => `${row.table_name}:"${row.tenant_id}"`).join(', ');
      throw new Error(
        `Cannot create the tenant domain: these tenant identifiers do not satisfy ` +
          `the required format ${TENANT_ID_FORMAT}: ${summary}. ` +
          `Normalize the data first; an empty identifier or a value that is not a ` +
          `lowercase slug cannot reference the new tenants table.`,
      );
    }

    await queryRunner.query(`
      CREATE TABLE tenants (
        tenant_id varchar(100) PRIMARY KEY,
        name varchar(150) NOT NULL CHECK (length(TRIM(name)) > 0),
        is_active boolean NOT NULL DEFAULT true,
        created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT tenants_tenant_id_format CHECK (tenant_id REGEXP '${TENANT_ID_FORMAT}')
      )
    `);

    // Backfill from the only anchor that existed before this migration. The
    // name is provisional (the identifier itself) and is meant to be renamed
    // through the administration API.
    await queryRunner.query(`
      INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
      SELECT DISTINCT tenant_id, tenant_id, true, NOW(), NOW()
      FROM facilities
    `);

    // The facility anchor becomes a real reference.
    await queryRunner.query(`
      ALTER TABLE facilities
      ADD CONSTRAINT fk_facilities_tenant
      FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
      ON DELETE RESTRICT
    `);

    // Legacy visits without a facility escape the Phase 8 composite pair
    // foreign key because a composite key is only enforced when every column is
    // non-NULL; this direct reference closes that gap so even a facility-less
    // visit names a real tenant.
    await queryRunner.query(`
      ALTER TABLE clinical_visits
      ADD CONSTRAINT fk_clinical_visits_tenant
      FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
      ON DELETE RESTRICT
    `);

    // Prescriptions always carry a facility, so the Phase 8 pair constraint
    // already covers them; this direct reference is deliberate defense in
    // depth and costs nothing at write time.
    await queryRunner.query(`
      ALTER TABLE prescriptions
      ADD CONSTRAINT fk_prescriptions_tenant
      FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
      ON DELETE RESTRICT
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE prescriptions DROP FOREIGN KEY fk_prescriptions_tenant');
    await queryRunner.query('ALTER TABLE clinical_visits DROP FOREIGN KEY fk_clinical_visits_tenant');
    await queryRunner.query('ALTER TABLE facilities DROP FOREIGN KEY fk_facilities_tenant');
    await queryRunner.query('DROP TABLE tenants');
  }
}
