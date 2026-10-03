import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateIdentityFacilityStaff1710000002000 implements MigrationInterface {
  name = 'CreateIdentityFacilityStaff1710000002000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE users (
        user_id char(36) PRIMARY KEY,
        login_identifier varchar(120) NOT NULL UNIQUE,
        password_hash varchar(255) NOT NULL,
        is_active boolean NOT NULL DEFAULT true,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    // The UNIQUE key is named explicitly so Phase 8 can drop and later restore
    // exactly this constraint by name.
    await queryRunner.query(`
      CREATE TABLE facilities (
        facility_id char(36) PRIMARY KEY,
        facility_code varchar(50) NOT NULL UNIQUE,
        facility_name varchar(150) NOT NULL,
        facility_type varchar(50) NOT NULL,
        municipality varchar(100),
        administrative_post varchar(100),
        village varchar(100),
        tenant_id varchar(100) NOT NULL,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL,
        CONSTRAINT facilities_tenant_id_key UNIQUE (tenant_id)
      )
    `);
    // MySQL parses an inline column level `REFERENCES` clause but never turns it
    // into a foreign key, so every reference is declared as a table constraint.
    await queryRunner.query(`
      CREATE TABLE facility_memberships (
        membership_id char(36) PRIMARY KEY,
        user_id char(36) NOT NULL,
        facility_id char(36) NOT NULL,
        role varchar(30) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE', 'PHARMACY')),
        is_active boolean NOT NULL DEFAULT true,
        created_at datetime NOT NULL,
        CONSTRAINT fk_facility_memberships_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
        CONSTRAINT fk_facility_memberships_facility FOREIGN KEY (facility_id) REFERENCES facilities(facility_id) ON DELETE RESTRICT,
        CONSTRAINT uq_facility_membership_user_facility UNIQUE (user_id, facility_id)
      )
    `);
    await queryRunner.query(`
      CREATE TABLE staff_profiles (
        staff_id char(36) PRIMARY KEY,
        user_id char(36) NOT NULL,
        facility_id char(36) NOT NULL,
        medical_license varchar(50) NOT NULL UNIQUE,
        profession varchar(30) NOT NULL CHECK (profession IN ('Doctor', 'Enfermeiru', 'Parteira', 'Farmasi')),
        verification_status varchar(20) NOT NULL DEFAULT 'Pending' CHECK (verification_status IN ('Pending', 'Approved', 'Rejected')),
        created_at datetime NOT NULL,
        CONSTRAINT fk_staff_profiles_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
        CONSTRAINT fk_staff_profiles_facility FOREIGN KEY (facility_id) REFERENCES facilities(facility_id) ON DELETE RESTRICT
      )
    `);
    // The index is created before the foreign key so the key reuses it rather
    // than letting MySQL add a second, constraint named index on the same column.
    await queryRunner.query('ALTER TABLE patients ADD COLUMN facility_id char(36) NULL');
    await queryRunner.query('CREATE INDEX idx_patients_facility_id ON patients (facility_id)');
    await queryRunner.query(
      'ALTER TABLE patients ADD CONSTRAINT fk_patients_facility FOREIGN KEY (facility_id) REFERENCES facilities(facility_id) ON DELETE RESTRICT',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE patients DROP FOREIGN KEY fk_patients_facility');
    await queryRunner.query('DROP INDEX idx_patients_facility_id ON patients');
    await queryRunner.query('ALTER TABLE patients DROP COLUMN facility_id');
    await queryRunner.query('DROP TABLE staff_profiles');
    await queryRunner.query('DROP TABLE facility_memberships');
    await queryRunner.query('DROP TABLE facilities');
    await queryRunner.query('DROP TABLE users');
  }
}
