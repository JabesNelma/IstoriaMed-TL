import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreatePatientAndClinicalVisitTables1710000000000 implements MigrationInterface {
  name = 'CreatePatientAndClinicalVisitTables1710000000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE patients (
        patient_id uuid PRIMARY KEY,
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
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL
      )
    `);
    await queryRunner.query(`
      CREATE UNIQUE INDEX uq_patients_no_ktp
      ON patients (no_ktp)
      WHERE no_ktp IS NOT NULL
    `);
    await queryRunner.query(`
      CREATE TABLE clinical_visits (
        visit_id uuid PRIMARY KEY,
        pasien_id uuid NOT NULL,
        tenant_id varchar(100) NOT NULL,
        staf_id uuid,
        visit_date timestamptz NOT NULL,
        keluhan_subjektif text NOT NULL,
        pemeriksaan_objektif text,
        analisis_asesmen text,
        rencana_tindakan text,
        kode_icd10 varchar(10) NOT NULL,
        nama_penyakit_lokal varchar(100),
        status_sinkronisasi varchar(20) NOT NULL DEFAULT 'Pending',
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
        CONSTRAINT fk_clinical_visits_patient
          FOREIGN KEY (pasien_id) REFERENCES patients(patient_id) ON DELETE RESTRICT
      )
    `);
    await queryRunner.query('CREATE INDEX idx_clinical_visits_patient_id ON clinical_visits (pasien_id)');
    await queryRunner.query('CREATE INDEX idx_clinical_visits_tenant_id ON clinical_visits (tenant_id)');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE clinical_visits');
    await queryRunner.query('DROP INDEX uq_patients_no_ktp');
    await queryRunner.query('DROP TABLE patients');
  }
}
