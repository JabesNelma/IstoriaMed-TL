import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSyncOperations1710000004000 implements MigrationInterface {
  name = 'AddSyncOperations1710000004000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // The entity type check is named explicitly so Phase 7 can drop and re-add
    // exactly this constraint by name.
    await queryRunner.query(`
      CREATE TABLE sync_operations (
        operation_id char(36) PRIMARY KEY,
        entity_type varchar(30) NOT NULL,
        operation_type varchar(20) NOT NULL CHECK (operation_type IN ('CREATE')),
        status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SYNCING', 'SYNCED', 'FAILED')),
        retry_count int NOT NULL DEFAULT 0,
        payload json,
        entity_id char(36),
        last_error text,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL,
        processed_at datetime,
        CONSTRAINT sync_operations_entity_type_check CHECK (entity_type IN ('PATIENT', 'CLINICAL_VISIT'))
      )
    `);
    await queryRunner.query('CREATE INDEX idx_sync_operations_status ON sync_operations (status)');
    await queryRunner.query('CREATE INDEX idx_sync_operations_created_at ON sync_operations (created_at)');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX idx_sync_operations_created_at ON sync_operations');
    await queryRunner.query('DROP INDEX idx_sync_operations_status ON sync_operations');
    await queryRunner.query('DROP TABLE sync_operations');
  }
}
