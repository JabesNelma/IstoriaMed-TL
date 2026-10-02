import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserRecord } from '../../database/entities/user.record';
import { FacilityMembershipRecord } from '../../database/entities/facility-membership.record';
import { AuthController } from './auth.controller';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { RolesGuard } from './roles.guard';
import type { JwtModuleOptions } from '@nestjs/jwt';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserRecord, FacilityMembershipRecord]),
    JwtModule.registerAsync({
      useFactory: (): JwtModuleOptions => {
        const secret = process.env.JWT_SECRET;
        if (!secret) throw new Error('JWT_SECRET is required to start authentication.');
        return { secret, signOptions: { expiresIn: (process.env.JWT_ACCESS_TOKEN_EXPIRES_IN ?? '15m') as NonNullable<JwtModuleOptions['signOptions']>['expiresIn'] } };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, AuthGuard, RolesGuard],
  exports: [AuthService, AuthGuard, RolesGuard, JwtModule],
})
export class AuthModule {}
