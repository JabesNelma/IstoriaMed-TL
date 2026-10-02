import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard, getAuthenticatedUser } from '../auth/auth.guard';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { SyncOperationRequestDto, SyncOperationResponseDto } from './dto/sync.dto';
import { SyncService } from './sync.service';

@Controller('api/sync')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('operations')
  async processOperation(
    @Body() dto: SyncOperationRequestDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<SyncOperationResponseDto> {
    return this.syncService.processOperation(dto.operation, getAuthenticatedUser(request));
  }
}
