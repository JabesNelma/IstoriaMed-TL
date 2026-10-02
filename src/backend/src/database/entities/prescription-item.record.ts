import { Column, Entity, Index, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';

import { MedicationRecord } from './medication.record';
import { PrescriptionRecord } from './prescription.record';

/**
 * One prescribed drug line inside a prescription.
 *
 * This entity only stores what the authorized medical professional prescribed.
 * It deliberately contains no dosing calculation, no interaction checking and no
 * inventory logic: those belong to later phases.
 *
 * ON DELETE RESTRICT keeps prescription history intact.
 */
@Entity({ name: 'prescription_items' })
@Index('idx_prescription_items_prescription_id', ['prescription_id'])
@Index('idx_prescription_items_medication_id', ['medication_id'])
export class PrescriptionItemRecord {
  @PrimaryColumn({ type: 'uuid', name: 'prescription_item_id' })
  prescription_item_id!: string;

  @Column({ type: 'uuid' })
  prescription_id!: string;

  @ManyToOne(() => PrescriptionRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'prescription_id', referencedColumnName: 'prescription_id' })
  prescription!: PrescriptionRecord;

  @Column({ type: 'uuid' })
  medication_id!: string;

  @ManyToOne(() => MedicationRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'medication_id', referencedColumnName: 'medication_id' })
  medication!: MedicationRecord;

  @Column({ type: 'varchar', length: 100 })
  dose!: string;

  @Column({ type: 'varchar', length: 100 })
  frequency!: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  route!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  duration!: string | null;

  @Column({ type: 'int' })
  quantity!: number;

  @Column({ type: 'varchar', length: 500, nullable: true })
  instructions!: string | null;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;
}