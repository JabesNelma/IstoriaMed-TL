import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { jest } from '@jest/globals';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { PasienService } from '../pasien/pasien.service';
import { IstoriaKlinisService } from './istoria_klinis.service';

describe('IstoriaKlinisService', () => {
  let service: IstoriaKlinisService;

  beforeEach(async () => {
    const patientService = {
      findOne: jest.fn(async () => ({ user_id: 'patient-1', facility_id: 'facility-1' })),
      findOneForUser: jest.fn(async () => ({ user_id: 'patient-1', facility_id: 'facility-1' })),
    };
    const repository = {
      create: jest.fn((record) => record),
      save: jest.fn(async (record) => record),
      find: jest.fn(async () => []),
      createQueryBuilder: jest.fn(() => ({ where: jest.fn().mockReturnThis(), andWhere: jest.fn().mockReturnThis(), orderBy: jest.fn().mockReturnThis(), getMany: jest.fn(async () => []), getOne: jest.fn(async () => null) })),
    };
    const staffRepository = {
      findOne: jest.fn(async () => ({ staff_id: 'staff-1', user_id: 'user-1', facility_id: 'facility-1', verification_status: 'Approved' })),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IstoriaKlinisService,
        { provide: PasienService, useValue: patientService },
        { provide: getRepositoryToken(ClinicalVisitRecord), useValue: repository },
        { provide: getRepositoryToken(StaffRecord), useValue: staffRepository },
      ],
    }).compile();

    service = module.get<IstoriaKlinisService>(IstoriaKlinisService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('creates a visit only for an existing patient', async () => {
    const visit = await service.create({
      pasien_id: '00000000-0000-0000-0000-000000000001',
      tenant_id: 'facility-a',
      keluhan_subjektif: 'Febre',
      kode_icd10: 'R50.9',
    }, { user_id: 'user-1', login_identifier: 'user@example.com', memberships: [{ facility_id: 'facility-1', tenant_id: 'facility-a', role: 'DOCTOR' }] });

    expect(visit.pasien_id).toBe('00000000-0000-0000-0000-000000000001');
    expect(visit.status_sinkronisasi).toBe('Pending');
    expect(visit.created_at).toBeInstanceOf(Date);
  });

  it('rejects a visit for an unknown patient', async () => {
    const patientService = (service as unknown as { pasienService: { findOne: jest.Mock } }).pasienService;
    patientService.findOne.mockResolvedValueOnce(undefined);
    await expect(service.create({
      pasien_id: '00000000-0000-0000-0000-000000000099',
      tenant_id: 'facility-a',
      keluhan_subjektif: 'Febre',
      kode_icd10: 'R50.9',
    }, { user_id: 'user-1', login_identifier: 'user@example.com', memberships: [{ facility_id: 'facility-1', tenant_id: 'facility-a', role: 'DOCTOR' }] })).rejects.toThrow(NotFoundException);
  });
});
