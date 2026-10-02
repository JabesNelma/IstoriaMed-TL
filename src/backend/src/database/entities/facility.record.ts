import { Column, Entity, Index, OneToMany, PrimaryColumn } from 'typeorm';
import type { FacilityMembershipRecord } from './facility-membership.record';
import type { StaffRecord } from './staff.record';

/**
 * A facility is the smallest unit of clinical ownership. A tenant may own many
 * facilities, so `tenant_id` is indexed for lookup but deliberately not unique.
 * The `(facility_id, tenant_id)` pair is the parent key for the composite
 * foreign keys that keep `clinical_visits` and `prescriptions` consistent.
 */
@Entity({ name: 'facilities' })
@Index('idx_facilities_tenant_id', ['tenant_id'])
@Index('uq_facilities_facility_tenant', ['facility_id', 'tenant_id'], { unique: true })
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

  @Column({ type: 'varchar', length: 100 })
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
