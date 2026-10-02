import { Column, Entity, Index, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';

import { FacilityRecord } from './facility.record';
import { PatientRecord } from './patient.record';
import { StaffRecord } from './staff.record';

@Entity({ name: 'clinical_visits' })
@Index('idx_clinical_visits_patient_id', ['pasien_id'])
@Index('idx_clinical_visits_tenant_id', ['tenant_id'])
@Index('idx_clinical_visits_facility_id', ['facility_id'])
export class ClinicalVisitRecord {
  @PrimaryColumn({ type: 'uuid', name: 'visit_id' })
  kunjungan_id!: string;

  @Column({ type: 'uuid' })
  pasien_id!: string;

  @ManyToOne(() => PatientRecord, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'pasien_id', referencedColumnName: 'patient_id' })
  pasien!: PatientRecord;

  @Column({ type: 'uuid', nullable: true })
  facility_id!: string | null;

  @ManyToOne(() => FacilityRecord, { nullable: true, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'facility_id', referencedColumnName: 'facility_id' })
  facility!: FacilityRecord | null;

  @Column({ type: 'varchar', length: 100 })
  tenant_id!: string;

  @Column({ type: 'uuid', nullable: true })
  staf_id!: string | null;

  @ManyToOne(() => StaffRecord, { nullable: true, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'staf_id', referencedColumnName: 'staff_id' })
  staf!: StaffRecord | null;

  @Column({ type: 'timestamptz', name: 'visit_date' })
  tanggal_kunjungan!: Date;

  @Column({ type: 'text' })
  keluhan_subjektif!: string;

  @Column({ type: 'text', nullable: true })
  pemeriksaan_objektif!: string | null;

  @Column({ type: 'text', nullable: true })
  analisis_asesmen!: string | null;

  @Column({ type: 'text', nullable: true })
  rencana_tindakan!: string | null;

  @Column({ type: 'varchar', length: 10 })
  kode_icd10!: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  nama_penyakit_lokal!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'Pending' })
  status_sinkronisasi!: 'Pending' | 'Synced' | 'Failed';

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;
}
