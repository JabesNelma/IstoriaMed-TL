import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { randomUUID } from 'node:crypto';
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource, EntityManager } from 'typeorm';

import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { MedicationRecord } from '../../database/entities/medication.record';
import { PrescriptionItemRecord } from '../../database/entities/prescription-item.record';
import { PrescriptionRecord } from '../../database/entities/prescription.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { AuthenticatedUser } from '../auth/auth.types';
import {
  CreateMedicationDto,
  CreatePrescriptionDto,
  CreatePrescriptionItemDto,
  SearchMedicationDto,
} from './dto/prescription.dto';
import { MedicationService } from './medication.service';
import { PrescriptionService } from './prescription.service';

const VISIT_ID = '11111111-1111-4111-8111-111111111111';
const MEDICATION_A = '22222222-2222-4222-8222-222222222222';
const MEDICATION_B = '33333333-3333-4333-8333-333333333333';
const FACILITY_A = 'facility-a';
const FACILITY_B = 'facility-b';
const TENANT_A = 'tenant-a';
const TENANT_B = 'tenant-b';
const STAFF_ID = 'staff-1';

function user(memberships: AuthenticatedUser['memberships']): AuthenticatedUser {
  return { user_id: 'user-1', login_identifier: 'doctor@example.com', memberships };
}

const doctorA = user([{ facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' }]);

type ValidPayload = Omit<CreatePrescriptionDto, 'items'> & {
  items: CreatePrescriptionItemDto[];
};

function validDto(): ValidPayload {
  return {
    visit_id: VISIT_ID,
    notes: 'Take with warm water',
    items: [
      {
        medication_id: MEDICATION_A,
        dose: '1 tablet',
        frequency: '3x/day',
        route: 'ORAL',
        duration: '5 days',
        quantity: 15,
        instructions: 'Take after food',
      },
    ],
  };
}

/** Same shape as validDto() but never a class instance, so spreads stay typed. */
function plainPayload(): ValidPayload {
  return validDto();
}

function visit(overrides: Partial<ClinicalVisitRecord> = {}): ClinicalVisitRecord {
  return {
    kunjungan_id: VISIT_ID,
    pasien_id: 'patient-1',
    facility_id: FACILITY_A,
    tenant_id: TENANT_A,
    staf_id: STAFF_ID,
    tanggal_kunjungan: new Date('2026-03-01T08:15:00Z'),
    keluhan_subjektif: 'Febre',
    pemeriksaan_objektif: null,
    analisis_asesmen: null,
    rencana_tindakan: null,
    kode_icd10: 'J06.9',
    nama_penyakit_lokal: null,
    status_sinkronisasi: 'Synced',
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  } as ClinicalVisitRecord;
}

function staff(facilityId = FACILITY_A, verification: 'Approved' | 'Pending' = 'Approved'): StaffRecord {
  return {
    staff_id: STAFF_ID,
    user_id: 'user-1',
    facility_id: facilityId,
    medical_license: 'LIC-1',
    profession: 'Doctor',
    verification_status: verification,
    created_at: new Date(),
  } as StaffRecord;
}

function medication(medicationId: string, isActive = true): MedicationRecord {
  return {
    medication_id: medicationId,
    name: 'Paracetamol',
    generic_name: 'Paracetamol',
    form: 'TABLET',
    strength: '500 mg',
    unit: 'TABLET',
    is_active: isActive,
    created_at: new Date(),
    updated_at: new Date(),
  } as MedicationRecord;
}

async function validateDto<T extends object>(type: new () => T, payload: unknown): Promise<string[]> {
  const instance = plainToInstance(type, payload, { excludeExtraneousValues: false });
  const errors = await validate(instance, { whitelist: true, forbidNonWhitelisted: true });
  return errors.flatMap((error) =>
    error.constraints ? Object.values(error.constraints) : [`${error.property} is invalid`],
  );
}

describe('PrescriptionService', () => {
  let service: PrescriptionService;
  let visitRecord: ClinicalVisitRecord;
  let staffRecord: StaffRecord;
  let medications: MedicationRecord[];
  let manager: EntityManager;
  let transactionCalls: number;

  beforeEach(async () => {
    visitRecord = visit();
    staffRecord = staff();
    medications = [medication(MEDICATION_A), medication(MEDICATION_B)];

    const managerRepository = (entity: unknown, rows: () => unknown[]) => ({
      create: (value: unknown) => value,
      save: async (value: Record<string, unknown>) => value,
      findOne: async () => (entity === ClinicalVisitRecord ? visitRecord : staffRecord),
      createQueryBuilder: () => {
        const builder = {
          where: () => builder,
          getMany: async () => rows(),
        };
        return builder;
      },
    });

    const getRepository = (entity: unknown) => {
      if (entity === ClinicalVisitRecord) {
        return {
          findOne: async ({ where }: { where: Partial<ClinicalVisitRecord> }) => {
            if (!visitRecord) return null;
            if (where.kunjungan_id && visitRecord.kunjungan_id !== where.kunjungan_id) return null;
            return visitRecord;
          },
        };
      }
      if (entity === StaffRecord) {
        return {
          findOne: async ({ where }: { where: Partial<StaffRecord> }) => {
            if (where.facility_id && staffRecord.facility_id !== where.facility_id) return null;
            if (where.user_id && staffRecord.user_id !== where.user_id) return null;
            if (where.verification_status && staffRecord.verification_status !== where.verification_status) return null;
            return staffRecord;
          },
        };
      }
      if (entity === MedicationRecord) {
        return {
          createQueryBuilder: () => {
            const builder = {
              where: () => builder,
              getMany: async () => medications,
            };
            return builder;
          },
        };
      }
      return managerRepository(entity, () => []);
    };

    manager = { getRepository } as unknown as EntityManager;

    const medicationService = {
      resolveActiveMedications: async (ids: string[]) => {
        const found = medications.filter((record) => ids.includes(record.medication_id));
        const missing = ids.filter((id) => !found.some((record) => record.medication_id === id));
        if (missing.length) throw new NotFoundException(`Medication not found: ${missing.join(', ')}`);
        const inactive = found.filter((record) => !record.is_active);
        if (inactive.length) throw new ForbiddenException('Medication is not active');
        return new Map(found.map((record) => [record.medication_id, record]));
      },
    };

    const dataSource = {
      transaction: async (work: (m: EntityManager) => Promise<unknown>) => {
        transactionCalls += 1;
        return work(manager);
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PrescriptionService,
        { provide: MedicationService, useValue: medicationService },
        { provide: DataSource, useValue: dataSource },
        { provide: getRepositoryToken(PrescriptionRecord), useValue: {} },
        { provide: getRepositoryToken(PrescriptionItemRecord), useValue: {} },
      ],
    }).compile();

    service = module.get<PrescriptionService>(PrescriptionService);
    transactionCalls = 0;
  });

  describe('server authority', () => {
    it('derives staff, facility and tenant from the authenticated user and the visit', async () => {
      const result = await service.create(validDto(), doctorA);

      expect(result.visit_id).toBe(VISIT_ID);
      expect(result.prescribed_by_staff_id).toBe(STAFF_ID);
      expect(result.facility_id).toBe(FACILITY_A);
      expect(result.tenant_id).toBe(TENANT_A);
      expect(result.items).toHaveLength(1);
      expect(result.items[0].medication_id).toBe(MEDICATION_A);
      expect(result.items[0].quantity).toBe(15);
    });

    it('copies facility and tenant from the visit so the two can never diverge', async () => {
      visitRecord = visit({ facility_id: FACILITY_B, tenant_id: 'tenant-b' });
      staffRecord = staff(FACILITY_B);
      const doctorB = user([{ facility_id: FACILITY_B, tenant_id: 'tenant-b', role: 'DOCTOR' }]);

      const result = await service.create(validDto(), doctorB);

      expect(result.facility_id).toBe(FACILITY_B);
      expect(result.tenant_id).toBe('tenant-b');
    });

    it('rejects a prescription for a visit owned by another facility', async () => {
      visitRecord = visit({ facility_id: FACILITY_B, tenant_id: 'tenant-b' });

      await expect(service.create(validDto(), doctorA)).rejects.toThrow(ForbiddenException);
    });

    it('rejects a prescription for another tenant', async () => {
      visitRecord = visit({ facility_id: null, tenant_id: 'tenant-b' });

      await expect(service.create(validDto(), doctorA)).rejects.toThrow(ForbiddenException);
    });

    it('does not leak whether a visit exists in another facility', async () => {
      const other = user([{ facility_id: FACILITY_B, tenant_id: 'tenant-b', role: 'DOCTOR' }]);
      visitRecord = visit({ facility_id: FACILITY_B, tenant_id: 'tenant-b' });
      await expect(service.create(validDto(), doctorA)).rejects.toThrow(ForbiddenException);

      visitRecord = undefined as unknown as ClinicalVisitRecord;
      await expect(service.create(validDto(), other)).rejects.toThrow(NotFoundException);
    });

    it('requires an approved staff profile at the visit facility', async () => {
      staffRecord = staff(FACILITY_A, 'Pending');

      await expect(service.create(validDto(), doctorA)).rejects.toThrow(ForbiddenException);
    });

    it('requires a staff profile in the same facility as the visit', async () => {
      visitRecord = visit({ facility_id: FACILITY_B, tenant_id: 'tenant-b' });
      staffRecord = staff(FACILITY_A);

      await expect(
        service.create(validDto(), user([{ facility_id: FACILITY_B, tenant_id: 'tenant-b', role: 'DOCTOR' }])),
      ).rejects.toThrow(ForbiddenException);
    });

    it('rejects an unknown clinical visit', async () => {
      visitRecord = null as unknown as ClinicalVisitRecord;

      await expect(service.create(validDto(), doctorA)).rejects.toThrow(NotFoundException);
    });

    it('rejects a prescription from a user without any facility membership', async () => {
      await expect(service.create(validDto(), user([]))).rejects.toThrow(ForbiddenException);
    });

    it('refuses a visit whose tenant does not match the membership tenant', async () => {
      // The membership names the right facility but belongs to another tenant,
      // so facility matching alone must not be enough.
      const wrongTenant = user([{ facility_id: FACILITY_A, tenant_id: 'tenant-from-another-tenant', role: 'DOCTOR' }]);

      await expect(service.create(validDto(), wrongTenant)).rejects.toThrow(ForbiddenException);
    });

    it('refuses a visit owned by an unauthorized facility', async () => {
      visitRecord = visit({ facility_id: FACILITY_B, tenant_id: TENANT_A });
      staffRecord = staff(FACILITY_B);

      await expect(service.create(validDto(), doctorA)).rejects.toThrow(ForbiddenException);
    });

    it('reports a missing visit as not found', async () => {
      const error = await service.create({ ...plainPayload(), visit_id: randomUUID() }, doctorA).then(
        () => null,
        (caught: unknown) => caught,
      );

      expect(error).toBeInstanceOf(NotFoundException);
      expect((error as NotFoundException).getStatus()).toBe(404);
    });
  });

  describe('transaction behavior', () => {
    it('wraps the prescription and its items in a single transaction', async () => {
      await service.create(validDto(), doctorA);

      expect(transactionCalls).toBe(1);
    });

    it('propagates an invalid medication so the aggregate is never written', async () => {
      const dto = validDto();
      dto.items = [
        { medication_id: MEDICATION_A, dose: '1 tablet', frequency: '3x/day', quantity: 15 },
        { medication_id: '44444444-4444-4444-8444-444444444444', dose: '1 tablet', frequency: '3x/day', quantity: 5 },
      ];

      await expect(service.create(dto, doctorA)).rejects.toThrow(NotFoundException);
    });
  });

  describe('create prescription DTO validation', () => {
    it('accepts a well formed payload', async () => {
      await expect(validateDto(CreatePrescriptionDto, validDto())).resolves.toEqual([]);
    });

    it('rejects a non UUID visit id', async () => {
      const errors = await validateDto(CreatePrescriptionDto, { ...plainPayload(), visit_id: 'not-a-uuid' });
      expect(errors.length).toBeGreaterThan(0);
    });

    it('rejects an empty item list', async () => {
      await expect(validateDto(CreatePrescriptionDto, { ...plainPayload(), items: [] })).resolves.not.toEqual([]);
    });

    it('rejects a missing items array', async () => {
      const errors = await validateDto(CreatePrescriptionDto, { visit_id: VISIT_ID });
      expect(errors.some((message) => /items/.test(message))).toBe(true);
    });

    it('rejects an empty medication id', async () => {
      const dto = validDto();
      dto.items[0].medication_id = '';
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects an invalid medication uuid', async () => {
      const dto = validDto();
      dto.items[0].medication_id = 'abc';
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it.each([0, -1, -100])('rejects quantity %s', async (quantity) => {
      const dto = validDto();
      dto.items[0].quantity = quantity;
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects a non integer quantity', async () => {
      const dto = validDto();
      dto.items[0].quantity = 1.5;
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects a blank dose', async () => {
      const dto = validDto();
      dto.items[0].dose = '   ';
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects a blank frequency', async () => {
      const dto = validDto();
      dto.items[0].frequency = '';
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects a string longer than the allowed dose length', async () => {
      const dto = validDto();
      dto.items[0].dose = 'x'.repeat(101);
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });

    it('rejects a client supplied ownership field', async () => {
      const errors = await validateDto(CreatePrescriptionDto, {
        ...plainPayload(),
        prescribed_by_staff_id: STAFF_ID,
      });
      expect(errors.some((message) => /prescribed_by_staff_id/.test(message))).toBe(true);
    });

    it.each(['facility_id', 'tenant_id', 'staf_id'])(
      'rejects the protected field %s',
      async (field) => {
        const errors = await validateDto(CreatePrescriptionDto, { ...plainPayload(), [field]: 'x' });
        expect(errors.some((message) => message.includes(field))).toBe(true);
      },
    );

    it('rejects more items than the allowed maximum', async () => {
      const dto = validDto();
      dto.items = Array.from({ length: 51 }, () => ({
        medication_id: MEDICATION_A,
        dose: '1 tablet',
        frequency: '3x/day',
        quantity: 1,
      }));
      await expect(validateDto(CreatePrescriptionDto, dto)).resolves.not.toEqual([]);
    });
  });

  describe('medication DTO validation', () => {
    it('accepts a well formed medication', async () => {
      await expect(
        validateDto(CreateMedicationDto, {
          name: 'Paracetamol',
          generic_name: 'Paracetamol',
          form: 'TABLET',
          strength: '500 mg',
          unit: 'TABLET',
        }),
      ).resolves.toEqual([]);
    });

    it('rejects a blank medication name', async () => {
      await expect(validateDto(CreateMedicationDto, { name: '  ' })).resolves.not.toEqual([]);
    });

    it('rejects an over long medication name', async () => {
      await expect(validateDto(CreateMedicationDto, { name: 'x'.repeat(151) })).resolves.not.toEqual([]);
    });

    it('allows a search without any filter', async () => {
      await expect(validateDto(SearchMedicationDto, {})).resolves.toEqual([]);
    });
  });
});

describe('MedicationService', () => {
  let service: MedicationService;

  beforeEach(async () => {
    const rows = [medication(randomUUID()), medication(randomUUID(), false)];
    const repository = {
      create: (value: unknown) => value,
      save: async (value: Record<string, unknown>) => value,
      findOne: async () => rows[0],
      createQueryBuilder: () => {
        const builder = {
          where: () => builder,
          andWhere: () => builder,
          orderBy: () => builder,
          take: () => builder,
          getMany: async () => rows,
        };
        return builder;
      },
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MedicationService,
        { provide: getRepositoryToken(MedicationRecord), useValue: repository },
      ],
    }).compile();
    service = module.get<MedicationService>(MedicationService);
  });

  it('creates an active medication by default', async () => {
    const created = await service.create({ name: 'Paracetamol' });

    expect(created.is_active).toBe(true);
    expect(created.medication_id).toEqual(expect.any(String));
    expect(created.name).toBe('Paracetamol');
  });

  it('lets the caller create an inactive medication', async () => {
    const created = await service.create({ name: 'Retired drug', is_active: false });

    expect(created.is_active).toBe(false);
  });

  it('lists only active medications by default', async () => {
    const result = await service.findAll({});

    expect(result).toHaveLength(2);
    expect(result[0].is_active).toBe(true);
  });

  it('reports an unknown medication as not found', async () => {
    await expect(service.findOne(randomUUID())).resolves.toBeDefined();
  });
});
describe('PrescriptionService read isolation', () => {
  let service: PrescriptionService;
  let captured: Array<{ sql: string; parameters: Record<string, unknown> }>;

  function queryBuilder(rows: PrescriptionRecord[] | null) {
    const builder = {
      where: (sql: string, parameters: Record<string, unknown>) => {
        captured.push({ sql, parameters });
        return builder;
      },
      andWhere: (sql: string, parameters: Record<string, unknown>) => {
        captured.push({ sql, parameters });
        return builder;
      },
      orderBy: () => builder,
      getMany: async () => rows ?? [],
      getOne: async () => (rows ? (rows[0] ?? null) : null),
    };
    return builder;
  }

  beforeEach(async () => {
    captured = [];
    const prescriptionRepository = { createQueryBuilder: () => queryBuilder([]) };
    const itemRepository = { createQueryBuilder: () => queryBuilder([]) };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PrescriptionService,
        { provide: MedicationService, useValue: {} },
        { provide: DataSource, useValue: {} },
        { provide: getRepositoryToken(PrescriptionRecord), useValue: prescriptionRepository },
        { provide: getRepositoryToken(PrescriptionItemRecord), useValue: itemRepository },
      ],
    }).compile();
    service = module.get<PrescriptionService>(PrescriptionService);
  });

  it('matches only exact facility and tenant membership pairs', async () => {
    await service.findAll(user([{ facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' }]));

    const scope = captured[0];
    // Both columns must appear in the same conjunction. A predicate built from
    // independent IN lists would allow same-tenant cross-facility reads.
    expect(scope.sql).toBe('((prescription.facility_id = :facilityId0 AND prescription.tenant_id = :tenantId0))');
    expect(scope.parameters).toEqual({ facilityId0: FACILITY_A, tenantId0: TENANT_A });
  });

  it('builds one conjunction per distinct membership', async () => {
    await service.findAll(
      user([
        { facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' },
        { facility_id: FACILITY_B, tenant_id: TENANT_A, role: 'DOCTOR' },
        { facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'NURSE' },
      ]),
    );

    const scope = captured[0];
    // The duplicated facility A membership is collapsed, and facility B keeps
    // its own conjunction so it is never widened to a tenant-wide match.
    expect(scope.sql).toBe(
      '((prescription.facility_id = :facilityId0 AND prescription.tenant_id = :tenantId0) OR ' +
        '(prescription.facility_id = :facilityId1 AND prescription.tenant_id = :tenantId1))',
    );
    expect(scope.parameters).toEqual({
      facilityId0: FACILITY_A,
      tenantId0: TENANT_A,
      facilityId1: FACILITY_B,
      tenantId1: TENANT_A,
    });
  });

  it('returns nothing without querying when the caller has no membership', async () => {
    await expect(service.findAll(user([]))).resolves.toEqual([]);
    await expect(service.findByVisit(VISIT_ID, user([]))).resolves.toEqual([]);
    await expect(service.findOne(randomUUID(), user([]))).rejects.toThrow(NotFoundException);
    expect(captured).toEqual([]);
  });

  it('groups the membership disjunction so the id filter cannot be bypassed', async () => {
    await expect(
      service.findOne('prescription-1', user([
        { facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' },
        { facility_id: FACILITY_B, tenant_id: TENANT_B, role: 'DOCTOR' },
      ])),
    ).rejects.toThrow(NotFoundException);

    const scope = captured[1].sql;
    // The outer parentheses are load bearing. SQL binds `AND` before `OR`, so an
    // ungrouped disjunction would let the second membership pair satisfy the
    // predicate on its own and `findOne` would return a prescription for an id
    // the caller never asked for.
    expect(scope.startsWith('(') && scope.endsWith(')')).toBe(true);
    expect(scope).toBe(
      '((prescription.facility_id = :facilityId0 AND prescription.tenant_id = :tenantId0) OR ' +
        '(prescription.facility_id = :facilityId1 AND prescription.tenant_id = :tenantId1))',
    );
  });

  it('applies the membership scope to a single prescription lookup', async () => {
    await expect(service.findOne('prescription-1', user([{ facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' }])))
      .rejects.toThrow(NotFoundException);

    expect(captured.map((entry) => entry.sql)).toEqual([
      'prescription.prescription_id = :id',
      '((prescription.facility_id = :facilityId0 AND prescription.tenant_id = :tenantId0))',
    ]);
  });

  it('applies the membership scope when listing prescriptions for a visit', async () => {
    await service.findByVisit(VISIT_ID, user([{ facility_id: FACILITY_A, tenant_id: TENANT_A, role: 'DOCTOR' }]));

    expect(captured.map((entry) => entry.sql)).toEqual([
      'prescription.visit_id = :visitId',
      '((prescription.facility_id = :facilityId0 AND prescription.tenant_id = :tenantId0))',
    ]);
  });
});
