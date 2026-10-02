import { Column, Entity, Index, PrimaryColumn } from 'typeorm';

export type SyncEntityType = 'PATIENT' | 'CLINICAL_VISIT';
export type SyncOperationType = 'CREATE';
export type SyncOperationStatus = 'PENDING' | 'SYNCING' | 'SYNCED' | 'FAILED';

@Entity({ name: 'sync_operations' })
@Index('idx_sync_operations_status', ['status'])
@Index('idx_sync_operations_created_at', ['created_at'])
export class SyncOperationRecord {
  @PrimaryColumn({ type: 'uuid', name: 'operation_id' })
  operation_id!: string;

  @Column({ type: 'varchar', length: 30 })
  entity_type!: SyncEntityType;

  @Column({ type: 'uuid', nullable: true })
  entity_id!: string | null;

  @Column({ type: 'varchar', length: 20 })
  operation_type!: SyncOperationType;

  @Column({ type: 'varchar', length: 20, default: 'PENDING' })
  status!: SyncOperationStatus;

  @Column({ type: 'int', default: 0 })
  retry_count!: number;

  @Column({ type: 'jsonb', nullable: true })
  payload!: Record<string, unknown> | null;

  @Column({ type: 'text', nullable: true })
  last_error!: string | null;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  processed_at!: Date | null;
}
