import { Column, Entity, OneToMany, PrimaryColumn } from 'typeorm';
import type { FacilityMembershipRecord } from './facility-membership.record';
import type { StaffRecord } from './staff.record';

@Entity({ name: 'users' })
export class UserRecord {
  @PrimaryColumn({ type: 'uuid', name: 'user_id' })
  user_id!: string;

  @Column({ type: 'varchar', length: 120, unique: true })
  login_identifier!: string;

  @Column({ type: 'varchar', length: 255, name: 'password_hash', select: false })
  password_hash!: string;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;

  @OneToMany('facility_memberships', 'user')
  memberships!: FacilityMembershipRecord[];

  @OneToMany('staff_profiles', 'user')
  staff_profiles!: StaffRecord[];
}
