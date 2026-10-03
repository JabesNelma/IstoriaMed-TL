import { MigrationInterface, QueryRunner } from 'typeorm';

export class WidenMedicalRecordNumber1710000001000 implements MigrationInterface {
  name = 'WidenMedicalRecordNumber1710000001000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE patients MODIFY COLUMN medical_record_number varchar(64) NOT NULL',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE patients MODIFY COLUMN medical_record_number varchar(32) NOT NULL',
    );
  }
}