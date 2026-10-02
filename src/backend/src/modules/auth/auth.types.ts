import { ApplicationRole } from '../../database/entities/facility-membership.record';

export interface AuthenticatedMembership {
  facility_id: string;
  tenant_id: string;
  role: ApplicationRole;
}

export interface AuthenticatedUser {
  user_id: string;
  login_identifier: string;
  memberships: AuthenticatedMembership[];
}

export interface JwtPayload {
  sub: string;
  login_identifier: string;
}
