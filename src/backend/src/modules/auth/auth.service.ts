import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { randomUUID } from 'node:crypto';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { UserRecord } from '../../database/entities/user.record';
import { FacilityMembershipRecord } from '../../database/entities/facility-membership.record';
import { LoginDto, RegisterUserDto } from './dto/auth.dto';
import { AuthenticatedUser, JwtPayload } from './auth.types';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(UserRecord) private readonly userRepository: Repository<UserRecord>,
    @InjectRepository(FacilityMembershipRecord) private readonly membershipRepository: Repository<FacilityMembershipRecord>,
    private readonly jwtService: JwtService,
  ) {}

  async register(data: RegisterUserDto): Promise<{ user: Omit<UserRecord, 'password_hash'> }> {
    const existing = await this.userRepository.findOne({ where: { login_identifier: data.login_identifier.toLowerCase() } });
    if (existing) throw new ConflictException('Login identifier already registered.');

    const now = new Date();
    const user = this.userRepository.create({
      user_id: randomUUID(),
      login_identifier: data.login_identifier.toLowerCase(),
      password_hash: await argon2.hash(data.password),
      is_active: true,
      created_at: now,
      updated_at: now,
    });
    const saved = await this.userRepository.save(user);
    return { user: this.toSafeUser(saved) };
  }

  async login(data: LoginDto): Promise<{ access_token: string; token_type: 'Bearer'; expires_in: string; user: AuthenticatedUser }> {
    const user = await this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password_hash')
      .where('LOWER(user.login_identifier) = LOWER(:login_identifier)', { login_identifier: data.login_identifier })
      .andWhere('user.is_active = :is_active', { is_active: true })
      .getOne();

    if (!user || !(await argon2.verify(user.password_hash, data.password))) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    // Memberships resolve through the facility and its tenant. A suspended
    // tenant (is_active = false) contributes no memberships, so the user has no
    // scope anywhere in it — the one central enforcement point for tenant
    // status. Suspension is reversible only by an authority whose own tenant is
    // still active.
    const memberships = await this.membershipRepository.find({
      where: { user_id: user.user_id, is_active: true, facility: { tenant: { is_active: true } } },
      relations: { facility: true },
    });
    const authenticatedUser: AuthenticatedUser = {
      user_id: user.user_id,
      login_identifier: user.login_identifier,
      memberships: memberships.map((membership) => ({
        facility_id: membership.facility_id,
        tenant_id: membership.facility.tenant_id,
        role: membership.role,
      })),
    };
    const payload: JwtPayload = { sub: user.user_id, login_identifier: user.login_identifier };
    const accessToken = await this.jwtService.signAsync(payload);
    return {
      access_token: accessToken,
      token_type: 'Bearer',
      expires_in: process.env.JWT_ACCESS_TOKEN_EXPIRES_IN ?? '15m',
      user: authenticatedUser,
    };
  }

  async verifyPayload(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.userRepository.findOne({ where: { user_id: payload.sub, is_active: true } });
    if (!user) throw new UnauthorizedException('User is inactive or does not exist.');
    // Same rule as login: memberships of an inactive tenant are invisible, so
    // every request re-derives scope from active tenants only.
    const memberships = await this.membershipRepository.find({
      where: { user_id: user.user_id, is_active: true, facility: { tenant: { is_active: true } } },
      relations: { facility: true },
    });
    return {
      user_id: user.user_id,
      login_identifier: user.login_identifier,
      memberships: memberships.map((membership) => ({
        facility_id: membership.facility_id,
        tenant_id: membership.facility.tenant_id,
        role: membership.role,
      })),
    };
  }

  private toSafeUser(user: UserRecord): Omit<UserRecord, 'password_hash'> {
    const { password_hash: _, ...safeUser } = user;
    return safeUser;
  }
}
