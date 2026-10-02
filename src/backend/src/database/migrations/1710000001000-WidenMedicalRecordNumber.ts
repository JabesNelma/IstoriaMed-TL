import { MigrationInterface, QueryRunner } from 'typeorm';

export class WidenMedicalRecordNumber1710000001000 implements MigrationInterface {
  name = 'WidenMedicalRecordNumber1710000001000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE patients ALTER COLUMN medical_record_number TYPE varchar(64)',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE patients ALTER COLUMN medical_record_number TYPE varchar(32)',
    );
  }
}