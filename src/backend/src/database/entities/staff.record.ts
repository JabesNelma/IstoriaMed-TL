import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import type { FacilityRecord } from './facility.record';
import type { UserRecord } from './user.record';

export type MedicalProfession = 'Doctor' | 'Enfermeiru' | 'Parteira' | 'Farmasi';
export type VerificationStatus = 'Pending' | 'Approved' | 'Rejected';

@Entity({ name: 'staff_profiles' })
export class StaffRecord {
  @PrimaryColumn({ type: 'uuid', name: 'staff_id' })
  staff_id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'uuid' })
  facility_id!: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  medical_license!: string;

  @Column({ type: 'varchar', length: 30 })
  profession!: MedicalProfession;

  @Column({ type: 'varchar', length: 20, default: 'Pending' })
  verification_status!: VerificationStatus;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @ManyToOne('users', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'user_id', referencedColumnName: 'user_id' })
  user!: UserRecord;

  @ManyToOne('facilities', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'facility_id', referencedColumnName: 'facility_id' })
  facility!: FacilityRecord;
}
