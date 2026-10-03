import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Phase 7 - Prescription and Medication domain foundation.
 *
 * Creates the medication reference catalog plus the prescription aggregate, and
 * widens the existing sync entity type check constraint so prescriptions can
 * reuse the Phase 6 offline queue. No previously applied migration is edited.
 */
export class CreatePrescriptionMedication1710000005000 implements MigrationInterface {
  name = 'CreatePrescriptionMedication1710000005000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // Shared clinical reference catalog. Not tenant or facility scoped.
    // `TRIM` is used rather than PostgreSQL's `btrim`; they are equivalent.
    await queryRunner.query(`
      CREATE TABLE medications (
        medication_id char(36) PRIMARY KEY,
        name varchar(150) NOT NULL CHECK (length(TRIM(name)) > 0),
        generic_name varchar(150),
        form varchar(50),
        strength varchar(50),
        unit varchar(50),
        is_active boolean NOT NULL DEFAULT true,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    await queryRunner.query('CREATE INDEX idx_medications_name ON medications (name)');
    await queryRunner.query('CREATE INDEX idx_medications_generic_name ON medications (generic_name)');
    await queryRunner.query('CREATE INDEX idx_medications_is_active ON medications (is_active)');

    await queryRunner.query(`
      CREATE TABLE prescriptions (
        prescription_id char(36) PRIMARY KEY,
        visit_id char(36) NOT NULL,
        prescribed_by_staff_id char(36) NOT NULL,
        facility_id char(36) NOT NULL,
        tenant_id varchar(100) NOT NULL CHECK (length(TRIM(tenant_id)) > 0),
        prescribed_at datetime NOT NULL,
        notes text,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    await queryRunner.query('CREATE INDEX idx_prescriptions_visit_id ON prescriptions (visit_id)');
    await queryRunner.query('CREATE INDEX idx_prescriptions_prescribed_by_staff_id ON prescriptions (prescribed_by_staff_id)');
    await queryRunner.query('CREATE INDEX idx_prescriptions_facility_id ON prescriptions (facility_id)');
    await queryRunner.query('CREATE INDEX idx_prescriptions_tenant_id ON prescriptions (tenant_id)');
    await queryRunner.query('CREATE INDEX idx_prescriptions_prescribed_at ON prescriptions (prescribed_at)');
    // MySQL silently creates a constraint named index for every foreign key that
    // has none, so the indexes above are created first and the foreign keys then
    // reuse them instead of adding redundant duplicates.
    await queryRunner.query(`
      ALTER TABLE prescriptions
      ADD CONSTRAINT fk_prescriptions_visit FOREIGN KEY (visit_id) REFERENCES clinical_visits (visit_id) ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE prescriptions
      ADD CONSTRAINT fk_prescriptions_prescribed_by_staff FOREIGN KEY (prescribed_by_staff_id) REFERENCES staff_profiles (staff_id) ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE prescriptions
      ADD CONSTRAINT fk_prescriptions_facility FOREIGN KEY (facility_id) REFERENCES facilities (facility_id) ON DELETE RESTRICT
    `);

    await queryRunner.query(`
      CREATE TABLE prescription_items (
        prescription_item_id char(36) PRIMARY KEY,
        prescription_id char(36) NOT NULL,
        medication_id char(36) NOT NULL,
        dose varchar(100) NOT NULL CHECK (length(TRIM(dose)) > 0),
        frequency varchar(100) NOT NULL CHECK (length(TRIM(frequency)) > 0),
        route varchar(50),
        duration varchar(50),
        quantity int NOT NULL CHECK (quantity > 0),
        instructions varchar(500),
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    await queryRunner.query('CREATE INDEX idx_prescription_items_prescription_id ON prescription_items (prescription_id)');
    await queryRunner.query('CREATE INDEX idx_prescription_items_medication_id ON prescription_items (medication_id)');
    await queryRunner.query(`
      ALTER TABLE prescription_items
      ADD CONSTRAINT fk_prescription_items_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions (prescription_id) ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE prescription_items
      ADD CONSTRAINT fk_prescription_items_medication FOREIGN KEY (medication_id) REFERENCES medications (medication_id) ON DELETE RESTRICT
    `);

    // Reuse the Phase 6 offline queue for prescriptions by widening the existing
    // entity type check constraint in place.
    await queryRunner.query(
      `ALTER TABLE sync_operations DROP CHECK sync_operations_entity_type_check`,
    );
    await queryRunner.query(`
      ALTER TABLE sync_operations
        ADD CONSTRAINT sync_operations_entity_type_check
        CHECK (entity_type IN ('PATIENT', 'CLINICAL_VISIT', 'PRESCRIPTION'))
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    // Guard: never silently erase prescription medical history.
    const prescriptions = (await queryRunner.query(
      'SELECT count(*) AS count FROM prescriptions',
    )) as Array<{ count: number }>;
    const synced = (await queryRunner.query(
      "SELECT count(*) AS count FROM sync_operations WHERE entity_type = 'PRESCRIPTION'",
    )) as Array<{ count: number }>;
    if ((prescriptions[0]?.count ?? 0) > 0 || (synced[0]?.count ?? 0) > 0) {
      throw new Error(
        'Refusing to revert the prescription domain while prescription records or prescription sync operations still exist.',
      );
    }

    await queryRunner.query('ALTER TABLE sync_operations DROP CHECK sync_operations_entity_type_check');
    await queryRunner.query(`
      ALTER TABLE sync_operations
        ADD CONSTRAINT sync_operations_entity_type_check
        CHECK (entity_type IN ('PATIENT', 'CLINICAL_VISIT'))
    `);
    await queryRunner.query('DROP TABLE prescription_items');
    await queryRunner.query('DROP TABLE prescriptions');
    await queryRunner.query('DROP TABLE medications');
  }
}