/** API representation of a tenant. */
export interface TenantEntity {
  tenant_id: string;
  name: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}
