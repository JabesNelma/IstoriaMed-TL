import { Column, Entity, OneToMany, PrimaryColumn } from 'typeorm';
import type { FacilityMembershipRecord } from './facility-membership.record';
import type { StaffRecord } from './staff.record';

@Entity({ name: 'facilities' })
export class FacilityRecord {
  @PrimaryColumn({ type: 'uuid', name: 'facility_id' })
  facility_id!: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  facility_code!: string;

  @Column({ type: 'varchar', length: 150 })
  facility_name!: string;

  @Column({ type: 'varchar', length: 50 })
  facility_type!: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  municipality!: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  administrative_post!: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  village!: string | null;

  @Column({ type: 'varchar', length: 100, unique: true })
  tenant_id!: string;

  @Column({ type: 'timestamptz' })
  created_at!: Date;

  @Column({ type: 'timestamptz' })
  updated_at!: Date;

  @OneToMany('facility_memberships', 'facility')
  memberships!: FacilityMembershipRecord[];

  @OneToMany('staff_profiles', 'facility')
  staff_profiles!: StaffRecord[];
}
