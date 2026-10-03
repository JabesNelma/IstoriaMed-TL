import { Column, Entity, Index, PrimaryColumn } from 'typeorm';

export type SyncEntityType = 'PATIENT' | 'CLINICAL_VISIT' | 'PRESCRIPTION';
export type SyncOperationType = 'CREATE';
export type SyncOperationStatus = 'PENDING' | 'SYNCING' | 'SYNCED' | 'FAILED';

@Entity({ name: 'sync_operations' })
@Index('idx_sync_operations_status', ['status'])
@Index('idx_sync_operations_created_at', ['created_at'])
export class SyncOperationRecord {
  @PrimaryColumn({ type: 'char', length: 36, name: 'operation_id' })
  operation_id!: string;

  @Column({ type: 'varchar', length: 30 })
  entity_type!: SyncEntityType;

  @Column({ type: 'char', length: 36, nullable: true })
  entity_id!: string | null;

  @Column({ type: 'varchar', length: 20 })
  operation_type!: SyncOperationType;

  @Column({ type: 'varchar', length: 20, default: 'PENDING' })
  status!: SyncOperationStatus;

  @Column({ type: 'int', default: 0 })
  retry_count!: number;

  @Column({ type: 'json', nullable: true })
  payload!: Record<string, unknown> | null;

  @Column({ type: 'text', nullable: true })
  last_error!: string | null;

  @Column({ type: 'datetime' })
  created_at!: Date;

  @Column({ type: 'datetime' })
  updated_at!: Date;

  @Column({ type: 'datetime', nullable: true })
  processed_at!: Date | null;
}
