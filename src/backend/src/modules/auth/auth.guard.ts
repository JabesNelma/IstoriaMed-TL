import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { AuthenticatedUser, JwtPayload } from './auth.types';

export type AuthenticatedRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly authService: AuthService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw new UnauthorizedException('Authentication required.');
    const token = header.slice('Bearer '.length).trim();
    if (!token) throw new UnauthorizedException('Authentication required.');

    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(token);
      request.user = await this.authService.verifyPayload(payload);
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired access token.');
    }
  }
}

export function getAuthenticatedUser(request: AuthenticatedRequest): AuthenticatedUser {
  if (!request.user) throw new UnauthorizedException('Authentication required.');
  return request.user;
}
