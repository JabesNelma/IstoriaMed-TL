import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Phase 8 - Database integrity and multi-facility foundation.
 *
 * Closes the three limitations recorded by the Phase 7.1 audit:
 *
 *   1. `clinical_visits.staf_id` had no foreign key, so a visit could point at
 *      a clinician that never existed.
 *   2. `tenant_id` is denormalized onto `clinical_visits` and `prescriptions`
 *      with nothing keeping it consistent with the owning facility.
 *   3. `facilities.tenant_id` was UNIQUE, which capped every tenant at exactly
 *      one facility.
 *
 * A genuine `tenant_id -> tenants` foreign key is deliberately NOT added. This
 * project has no `tenants` table and no Tenant entity; tenant identity is a free
 * text label whose only anchor is `facilities.tenant_id`. Referencing it would
 * require inventing a new domain, which is out of scope and would be fake
 * referential integrity. Instead the pair itself is constrained: a
 * `(facility_id, tenant_id)` unique key on `facilities` becomes the parent key
 * for composite foreign keys on the child tables, so a child row can no longer
 * claim a tenant that contradicts the facility it belongs to. That is the exact
 * defect class the Phase 7.1 authorization fix had to defend against at
 * runtime, now enforced by the schema.
 *
 * Legacy clinical visits predate facility assignment and keep `facility_id IS
 * NULL`. A composite foreign key is only enforced when every referencing column
 * is non-NULL, so those legacy rows stay valid and stay visible to their own
 * tenant through the authorization layer.
 *
 * No previously applied migration is edited.
 */
export class HardenDatabaseIntegrity1710000006000 implements MigrationInterface {
  name = 'HardenDatabaseIntegrity1710000006000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // Goal C: a tenant may own several facilities. The uniqueness that made that
    // impossible is replaced by a plain lookup index. MySQL stores a UNIQUE
    // constraint as an index, so it is dropped through DROP INDEX.
    await queryRunner.query('ALTER TABLE facilities DROP INDEX facilities_tenant_id_key');
    await queryRunner.query('CREATE INDEX idx_facilities_tenant_id ON facilities (tenant_id)');

    // The pair (facility, tenant) is now the referential anchor for every
    // tenant scoped child table. facility_id is already the primary key, so
    // this constraint can never fail on existing rows.
    await queryRunner.query(
      'ALTER TABLE facilities ADD CONSTRAINT uq_facilities_facility_tenant UNIQUE (facility_id, tenant_id)',
    );

    // Goal A: a clinical visit must reference a real staff profile. RESTRICT
    // keeps clinical history from being erased by removing a clinician.
    await queryRunner.query(`
      ALTER TABLE clinical_visits
      ADD CONSTRAINT fk_clinical_visits_staf
      FOREIGN KEY (staf_id) REFERENCES staff_profiles (staff_id)
      ON DELETE RESTRICT
    `);

    // Goal B (pair level): tenant_id can no longer disagree with the facility.
    await queryRunner.query(`
      ALTER TABLE clinical_visits
      ADD CONSTRAINT fk_clinical_visits_facility_tenant
      FOREIGN KEY (facility_id, tenant_id)
      REFERENCES facilities (facility_id, tenant_id)
      ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE prescriptions
      ADD CONSTRAINT fk_prescriptions_facility_tenant
      FOREIGN KEY (facility_id, tenant_id)
      REFERENCES facilities (facility_id, tenant_id)
      ON DELETE RESTRICT
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE prescriptions DROP FOREIGN KEY fk_prescriptions_facility_tenant');
    await queryRunner.query('ALTER TABLE clinical_visits DROP FOREIGN KEY fk_clinical_visits_facility_tenant');
    await queryRunner.query('ALTER TABLE clinical_visits DROP FOREIGN KEY fk_clinical_visits_staf');
    await queryRunner.query('ALTER TABLE facilities DROP INDEX uq_facilities_facility_tenant');
    await queryRunner.query('DROP INDEX idx_facilities_tenant_id ON facilities');
    // MySQL does not remove the supporting index when a foreign key is dropped,
    // so the indexes it auto-created for the two keys above have to go too.
    // `fk_clinical_visits_facility_tenant` in particular still covers
    // facility_id and would otherwise block a later `DROP COLUMN facility_id`.
    await queryRunner.query('DROP INDEX fk_prescriptions_facility_tenant ON prescriptions');
    await queryRunner.query('DROP INDEX fk_clinical_visits_facility_tenant ON clinical_visits');
    await queryRunner.query('DROP INDEX fk_clinical_visits_staf ON clinical_visits');

    // Reinstating UNIQUE (tenant_id) is only possible while every facility
    // still owns a distinct tenant. Fail loudly and descriptively instead of
    // letting the database emit an opaque constraint violation.
    const duplicates: Array<{ tenant_id: string; facility_count: number }> = await queryRunner.query(`
      SELECT tenant_id, count(*) AS facility_count
      FROM facilities
      GROUP BY tenant_id
      HAVING count(*) > 1
    `);
    if (duplicates.length) {
      const summary = duplicates.map((row) => `${row.tenant_id} (${row.facility_count})`).join(', ');
      throw new Error(
        `Cannot restore UNIQUE (facilities.tenant_id): these tenants now own more than ` +
          `one facility: ${summary}. Merge or reassign those facilities before rolling back.`,
      );
    }

    await queryRunner.query('ALTER TABLE facilities ADD CONSTRAINT facilities_tenant_id_key UNIQUE (tenant_id)');
  }
}