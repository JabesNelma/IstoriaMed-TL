import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFacilityToClinicalVisits1710000003000 implements MigrationInterface {
  name = 'AddFacilityToClinicalVisits1710000003000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // The index is created before the foreign key so the key reuses it rather
    // than letting MySQL add a second, constraint named index on the same column.
    await queryRunner.query('ALTER TABLE clinical_visits ADD COLUMN facility_id char(36) NULL');
    await queryRunner.query('CREATE INDEX idx_clinical_visits_facility_id ON clinical_visits (facility_id)');
    await queryRunner.query(
      'ALTER TABLE clinical_visits ADD CONSTRAINT fk_clinical_visits_facility FOREIGN KEY (facility_id) REFERENCES facilities(facility_id) ON DELETE RESTRICT',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE clinical_visits DROP FOREIGN KEY fk_clinical_visits_facility');
    await queryRunner.query('DROP INDEX idx_clinical_visits_facility_id ON clinical_visits');
    await queryRunner.query('ALTER TABLE clinical_visits DROP COLUMN facility_id');
  }
}
