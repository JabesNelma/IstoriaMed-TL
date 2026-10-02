import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSyncOperations1710000004000 implements MigrationInterface {
  name = 'AddSyncOperations1710000004000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE sync_operations (
        operation_id uuid PRIMARY KEY,
        entity_type varchar(30) NOT NULL CHECK (entity_type IN ('PATIENT', 'CLINICAL_VISIT')),
        entity_id uuid,
        operation_type varchar(20) NOT NULL CHECK (operation_type IN ('CREATE')),
        status varchar(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SYNCING', 'SYNCED', 'FAILED')),
        retry_count integer NOT NULL DEFAULT 0,
        payload jsonb,
        last_error text,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
        processed_at timestamptz
      )
    `);
    await queryRunner.query('CREATE INDEX idx_sync_operations_status ON sync_operations (status)');
    await queryRunner.query('CREATE INDEX idx_sync_operations_created_at ON sync_operations (created_at)');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX idx_sync_operations_created_at');
    await queryRunner.query('DROP INDEX idx_sync_operations_status');
    await queryRunner.query('DROP TABLE sync_operations');
  }
}
