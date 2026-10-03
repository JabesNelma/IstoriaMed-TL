import { Column, Entity, OneToMany, PrimaryColumn } from 'typeorm';
import type { FacilityRecord } from './facility.record';

/**
 * A tenant is a health system (a municipality health office, an NGO network, a
 * hospital group) that owns one or more facilities. Phase 9 replaces the free
 * text label that previously anchored tenant identity: the identifier is now a
 * validated lowercase slug and the primary key of this table.
 *
 * The natural key is deliberate. `facilities.tenant_id`, and the denormalized
 * `tenant_id` columns on `clinical_visits` and `prescriptions`, are varchar(100)
 * strings whose composite pair constraints point at `facilities`; keeping the
 * same value space means those constraints and the pair based authorization
 * layer work unchanged.
 *
 * An inactive tenant suspends every membership that resolves through its
 * facilities: `AuthService` filters inactive tenants out of the authenticated
 * membership list, so a suspended tenant has no scope anywhere.
 */
@Entity({ name: 'tenants' })
export class TenantRecord {
  @PrimaryColumn({ type: 'varchar', length: 100, name: 'tenant_id' })
  tenant_id!: string;

  @Column({ type: 'varchar', length: 150 })
  name!: string;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ type: 'datetime' })
  created_at!: Date;

  @Column({ type: 'datetime' })
  updated_at!: Date;

  @OneToMany('facilities', 'tenant')
  facilities!: FacilityRecord[];
}
