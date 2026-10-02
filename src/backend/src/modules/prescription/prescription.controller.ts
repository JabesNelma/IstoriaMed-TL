import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';

import { AuthGuard, getAuthenticatedUser } from '../auth/auth.guard';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { CreateMedicationDto, CreatePrescriptionDto, SearchMedicationDto } from './dto/prescription.dto';
import { MedicationEntity } from './medication.entity';
import { MedicationService } from './medication.service';
import { PrescriptionEntity } from './prescription.entity';
import { PrescriptionService } from './prescription.service';

/**
 * Prescription endpoints.
 *
 * Role policy: the same medical roles already authorized to write a clinical
 * visit in Phase 5. PHARMACY is deliberately excluded because it has no clinical
 * write access anywhere in this application. No new roles were invented.
 */
@Controller('api/prescriptions')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE')
export class PrescriptionController {
  constructor(private readonly prescriptionService: PrescriptionService) {}

  @Post()
  create(
    @Body() data: CreatePrescriptionDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<PrescriptionEntity> {
    return this.prescriptionService.create(data, getAuthenticatedUser(request));
  }

  @Get()
  findAll(@Req() request: AuthenticatedRequest): Promise<PrescriptionEntity[]> {
    return this.prescriptionService.findAll(getAuthenticatedUser(request));
  }

  // Declared before the `:id` route so the literal prefix always wins.
  @Get('visit/:visitId')
  findByVisit(
    @Param('visitId') visitId: string,
    @Req() request: AuthenticatedRequest,
  ): Promise<PrescriptionEntity[]> {
    return this.prescriptionService.findByVisit(visitId, getAuthenticatedUser(request));
  }

  @Get(':id')
  findOne(
    @Param('id') id: string,
    @Req() request: AuthenticatedRequest,
  ): Promise<PrescriptionEntity> {
    return this.prescriptionService.findOne(id, getAuthenticatedUser(request));
  }
}

/**
 * Medication reference catalog.
 *
 * The catalog is shared, non patient reference data, so every authenticated role
 * may read it (including PHARMACY). Creating catalog rows is an administrative
 * task and is limited to the administrative roles, mirroring how the rest of the
 * application treats catalog level writes.
 */
@Controller('api/medications')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN', 'DOCTOR', 'NURSE', 'MIDWIFE', 'PHARMACY')
export class MedicationController {
  constructor(private readonly medicationService: MedicationService) {}

  @Get()
  findAll(@Query() search: SearchMedicationDto): Promise<MedicationEntity[]> {
    return this.medicationService.findAll(search);
  }

  @Get(':id')
  findOne(@Param('id') id: string): Promise<MedicationEntity> {
    return this.medicationService.findOne(id);
  }
}

@Controller('api/admin/medications')
@UseGuards(AuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'SYSTEM_ADMIN')
export class MedicationAdminController {
  constructor(private readonly medicationService: MedicationService) {}

  @Post()
  create(@Body() data: CreateMedicationDto): Promise<MedicationEntity> {
    return this.medicationService.create(data);
  }
}