import { Column, Entity, Index, PrimaryColumn } from 'typeorm';

/**
 * Global medication reference catalog.
 *
 * Medications are deliberately NOT tenant or facility scoped: a drug reference
 * is shared clinical reference data, not patient data. There is no national
 * catalog bundled with the project; rows are created through the API only.
 */
@Entity({ name: 'medications' })
@Index('idx_medications_name', ['name'])
@Index('idx_medications_generic_name', ['generic_name'])
@Index('idx_medications_is_active', ['is_active'])
export class MedicationRecord {
  @PrimaryColumn({ type: 'uuid', name: 'medication_id' })
  medication_id!: string;

  @Column({ type: 'varchar', length: 150 })
  name!: string;

  @Column({ type: 'varchar', length: 150, nullable: true })
  generic_name!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  form!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  strength!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  unit!: string | null;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;
}