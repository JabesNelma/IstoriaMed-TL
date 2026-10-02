import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateIdentityFacilityStaff1710000002000 implements MigrationInterface {
  name = 'CreateIdentityFacilityStaff1710000002000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE users (
        user_id uuid PRIMARY KEY,
        login_identifier varchar(120) NOT NULL UNIQUE,
        password_hash varchar(255) NOT NULL,
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL
      )
    `);
    await queryRunner.query(`
      CREATE TABLE facilities (
        facility_id uuid PRIMARY KEY,
        facility_code varchar(50) NOT NULL UNIQUE,
        facility_name varchar(150) NOT NULL,
        facility_type varchar(50) NOT NULL,
        municipality varchar(100),
        administrative_post varchar(100),
        village varchar(100),
        tenant_id varchar(100) NOT NULL UNIQUE,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL
      )
    `);
    await queryRunner.query(`
      CREATE TABLE facility_memberships (
        membership_id uuid PRIMARY KEY,
        user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
        facility_id uuid NOT NULL REFERENCES facilities(facility_id) ON DELETE RESTRICT,
        role varchar(30) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE', 'PHARMACY')),
        is_active boolean NOT NULL DEFAULT true,
        created_at timestamptz NOT NULL,
        CONSTRAINT uq_facility_membership_user_facility UNIQUE (user_id, facility_id)
      )
    `);
    await queryRunner.query(`
      CREATE TABLE staff_profiles (
        staff_id uuid PRIMARY KEY,
        user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
        facility_id uuid NOT NULL REFERENCES facilities(facility_id) ON DELETE RESTRICT,
        medical_license varchar(50) NOT NULL UNIQUE,
        profession varchar(30) NOT NULL CHECK (profession IN ('Doctor', 'Enfermeiru', 'Parteira', 'Farmasi')),
        verification_status varchar(20) NOT NULL DEFAULT 'Pending' CHECK (verification_status IN ('Pending', 'Approved', 'Rejected')),
        created_at timestamptz NOT NULL
      )
    `);
    await queryRunner.query('ALTER TABLE patients ADD COLUMN facility_id uuid REFERENCES facilities(facility_id) ON DELETE RESTRICT');
    await queryRunner.query('CREATE INDEX idx_patients_facility_id ON patients (facility_id)');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX idx_patients_facility_id');
    await queryRunner.query('ALTER TABLE patients DROP COLUMN facility_id');
    await queryRunner.query('DROP TABLE staff_profiles');
    await queryRunner.query('DROP TABLE facility_memberships');
    await queryRunner.query('DROP TABLE facilities');
    await queryRunner.query('DROP TABLE users');
  }
}
