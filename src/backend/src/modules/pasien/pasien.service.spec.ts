import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException } from '@nestjs/common';
import { jest } from '@jest/globals';
import { getRepositoryToken } from '@nestjs/typeorm';
import { QueryFailedError } from 'typeorm';
import { PatientRecord } from '../../database/entities/patient.record';
import { PasienService } from './pasien.service';

describe('PasienService', () => {
  let service: PasienService;

  beforeEach(async () => {
    const repository = {
      create: jest.fn((record) => record),
      save: jest.fn(async (record) => record),
      find: jest.fn(async () => []),
      findOne: jest.fn(async () => undefined),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PasienService,
        { provide: getRepositoryToken(PatientRecord), useValue: repository },
      ],
    }).compile();

    service = module.get<PasienService>(PasienService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('creates a patient without KTP and assigns a medical record number', async () => {
    const patient = await service.create({
      no_ktp: null,
      nama_lengkap: 'Pasiente Emerjensia',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }, { user_id: 'user-1', login_identifier: 'user@example.com', memberships: [{ facility_id: 'facility-1', tenant_id: 'tenant-a', role: 'DOCTOR' }] });

    expect(patient.no_ktp).toBeNull();
    expect(patient.medical_record_number).toMatch(/^MRN-/);
    expect(patient.tanggal_lahir).toEqual(new Date('1990-01-01'));
  });

  it('maps a database unique violation to a conflict', async () => {
    const data = {
      no_ktp: '123',
      nama_lengkap: 'Primeiru Pasiente',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki' as const,
    };

    const repository = (service as unknown as { patientRepository: { save: jest.Mock } }).patientRepository;
    repository.save.mockRejectedValueOnce(Object.assign(new QueryFailedError('INSERT', [], new Error()), {
      driverError: { code: '23505' },
    }));

    await expect(service.create(data, { user_id: 'user-1', login_identifier: 'user@example.com', memberships: [{ facility_id: 'facility-1', tenant_id: 'tenant-a', role: 'DOCTOR' }] })).rejects.toThrow(ConflictException);
  });
});
