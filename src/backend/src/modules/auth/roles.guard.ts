import { CanActivate, ExecutionContext, ForbiddenException, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthenticatedRequest, getAuthenticatedUser } from './auth.guard';
import { ApplicationRole } from '../../database/entities/facility-membership.record';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: ApplicationRole[]) => SetMetadata(ROLES_KEY, roles);

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<ApplicationRole[]>(ROLES_KEY, [context.getHandler(), context.getClass()]);
    if (!roles?.length) return true;
    const user = getAuthenticatedUser(context.switchToHttp().getRequest<AuthenticatedRequest>());
    if (!user.memberships.some((membership) => roles.includes(membership.role))) {
      throw new ForbiddenException('Insufficient role.');
    }
    return true;
  }
}
