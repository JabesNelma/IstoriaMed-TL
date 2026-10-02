import { Column, Entity, Index, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import type { FacilityRecord } from './facility.record';
import type { UserRecord } from './user.record';

export type ApplicationRole = 'SUPER_ADMIN' | 'SYSTEM_ADMIN' | 'DOCTOR' | 'NURSE' | 'MIDWIFE' | 'PHARMACY';

@Entity({ name: 'facility_memberships' })
@Index('uq_facility_membership_user_facility', ['user_id', 'facility_id'], { unique: true })
export class FacilityMembershipRecord {
  @PrimaryColumn({ type: 'uuid', name: 'membership_id' })
  membership_id!: string;

  @Column({ type: 'uuid' })
  user_id!: string;

  @Column({ type: 'uuid' })
  facility_id!: string;

  @Column({ type: 'varchar', length: 30 })
  role!: ApplicationRole;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @ManyToOne('users', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'user_id', referencedColumnName: 'user_id' })
  user!: UserRecord;

  @ManyToOne('facilities', { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'facility_id', referencedColumnName: 'facility_id' })
  facility!: FacilityRecord;
}
