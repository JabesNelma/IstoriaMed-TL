import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePatientAndClinicalVisitTables1710000000000 implements MigrationInterface {
  name = 'CreatePatientAndClinicalVisitTables1710000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE patients (
        patient_id char(36) PRIMARY KEY,
        medical_record_number varchar(32) NOT NULL UNIQUE,
        no_ktp varchar(50),
        nama_lengkap varchar(100) NOT NULL,
        tanggal_lahir date NOT NULL,
        tempat_lahir varchar(100) NOT NULL,
        jenis_kelamin varchar(20) NOT NULL CHECK (jenis_kelamin IN ('Laki-laki', 'Perempuan')),
        municipality varchar(100),
        administrative_post varchar(100),
        village varchar(100),
        fingerprint_hash text,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    // MySQL has no partial indexes. A plain UNIQUE index treats every NULL as
    // distinct, so it already permits many patients without a KTP number while
    // still rejecting a repeated one: the same guarantee the PostgreSQL
    // `WHERE no_ktp IS NOT NULL` form gave.
    await queryRunner.query('CREATE UNIQUE INDEX uq_patients_no_ktp ON patients (no_ktp)');
    await queryRunner.query(`
      CREATE TABLE clinical_visits (
        visit_id char(36) PRIMARY KEY,
        pasien_id char(36) NOT NULL,
        tenant_id varchar(100) NOT NULL,
        staf_id char(36),
        visit_date datetime NOT NULL,
        keluhan_subjektif text NOT NULL,
        pemeriksaan_objektif text,
        analisis_asesmen text,
        rencana_tindakan text,
        kode_icd10 varchar(10) NOT NULL,
        nama_penyakit_lokal varchar(100),
        status_sinkronisasi varchar(20) NOT NULL DEFAULT 'Pending',
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    `);
    await queryRunner.query('CREATE INDEX idx_clinical_visits_patient_id ON clinical_visits (pasien_id)');
    await queryRunner.query('CREATE INDEX idx_clinical_visits_tenant_id ON clinical_visits (tenant_id)');
    // MySQL silently creates a constraint named index for every foreign key that
    // has none, so the indexes above are created first and the foreign key then
    // reuses them instead of adding a redundant duplicate.
    await queryRunner.query(`
      ALTER TABLE clinical_visits
      ADD CONSTRAINT fk_clinical_visits_patient
      FOREIGN KEY (pasien_id) REFERENCES patients(patient_id) ON DELETE RESTRICT
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE clinical_visits');
    await queryRunner.query('DROP INDEX uq_patients_no_ktp ON patients');
    await queryRunner.query('DROP TABLE patients');
  }
}
