import { Column, Entity, Index, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';

import { ClinicalVisitRecord } from './clinical-visit.record';
import { FacilityRecord } from './facility.record';
import { StaffRecord } from './staff.record';

/**
 * A medication prescription written by an authorized medical professional for
 * one clinical visit.
 *
 * `prescribed_by_staff_id`, `facility_id` and `tenant_id` are always derived by
 * the server from the authenticated user and the owning clinical visit. They are
 * never accepted from the client.
 *
 * Every foreign key uses ON DELETE RESTRICT so medical history can never be
 * erased by a cascading delete.
 */
@Entity({ name: 'prescriptions' })
@Index('idx_prescriptions_visit_id', ['visit_id'])
@Index('idx_prescriptions_prescribed_by_staff_id', ['prescribed_by_staff_id'])
@Index('idx_prescriptions_facility_id', ['facility_id'])
@Index('idx_prescriptions_tenant_id', ['tenant_id'])
@Index('idx_prescriptions_prescribed_at', ['prescribed_at'])
export class PrescriptionRecord {
  @PrimaryColumn({ type: 'char', length: 36, name: 'prescription_id' })
  prescription_id!: string;

  @Column({ type: 'char', length: 36 })
  visit_id!: string;

  @ManyToOne(() => ClinicalVisitRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'visit_id', referencedColumnName: 'kunjungan_id' })
  visit!: ClinicalVisitRecord;

  @Column({ type: 'char', length: 36 })
  prescribed_by_staff_id!: string;

  @ManyToOne(() => StaffRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'prescribed_by_staff_id', referencedColumnName: 'staff_id' })
  prescribedByStaff!: StaffRecord;

  @Column({ type: 'char', length: 36 })
  facility_id!: string;

  @ManyToOne(() => FacilityRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'facility_id', referencedColumnName: 'facility_id' })
  facility!: FacilityRecord;

  @Column({ type: 'varchar', length: 100 })
  tenant_id!: string;

  @Column({ type: 'datetime' })
  prescribed_at!: Date;

  @Column({ type: 'text', nullable: true })
  notes!: string | null;

  @Column({ type: 'datetime' })
  created_at!: Date;

  @Column({ type: 'datetime' })
  updated_at!: Date;
}