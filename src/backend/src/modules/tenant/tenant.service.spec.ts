import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { jest } from '@jest/globals';
import { getRepositoryToken } from '@nestjs/typeorm';
import { TenantRecord } from '../../database/entities/tenant.record';
import { TenantService } from './tenant.service';

describe('TenantService', () => {
  let service: TenantService;

  const createQueryBuilderMock = () => {
    const builder = {
      andWhere: jest.fn(() => builder),
      orderBy: jest.fn(() => builder),
      getMany: jest.fn(async () => []),
    };
    return builder;
  };

  beforeEach(async () => {
    const repository = {
      create: jest.fn((record) => record),
      save: jest.fn(async (record) => record),
      findOne: jest.fn(async () => undefined),
      createQueryBuilder: jest.fn(() => createQueryBuilderMock()),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TenantService,
        { provide: getRepositoryToken(TenantRecord), useValue: repository },
      ],
    }).compile();

    service = module.get<TenantService>(TenantService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('creates a tenant as active with the submitted identifier and name', async () => {
    const tenant = await service.create({ tenant_id: 'chc-dili', name: 'CHC Dili' });

    expect(tenant.tenant_id).toBe('chc-dili');
    expect(tenant.name).toBe('CHC Dili');
    expect(tenant.is_active).toBe(true);
    expect(tenant.created_at).toBeInstanceOf(Date);
    expect(tenant.updated_at).toBeInstanceOf(Date);
  });

  it('rejects a duplicate tenant identifier as a conflict', async () => {
    const repository = (service as unknown as { tenantRepository: { findOne: jest.Mock } }).tenantRepository;
    repository.findOne.mockResolvedValueOnce({ tenant_id: 'chc-dili', name: 'CHC Dili', is_active: true });

    await expect(service.create({ tenant_id: 'chc-dili', name: 'Another Dili' })).rejects.toThrow(ConflictException);
  });

  it('lists active tenants only unless include_inactive is requested', async () => {
    const repository = (service as unknown as { tenantRepository: { createQueryBuilder: jest.Mock } }).tenantRepository;
    const builder = createQueryBuilderMock();
    builder.getMany.mockResolvedValueOnce([]);
    repository.createQueryBuilder.mockReturnValueOnce(builder);

    await service.findAll({});

    expect(builder.andWhere).toHaveBeenCalledWith('tenant.is_active = true');

    await service.findAll({ include_inactive: true });

    expect(builder.andWhere).toHaveBeenCalledTimes(1);
  });

  it('returns one tenant and reports a missing one as not found', async () => {
    const repository = (service as unknown as { tenantRepository: { findOne: jest.Mock } }).tenantRepository;
    repository.findOne.mockResolvedValueOnce({ tenant_id: 'chc-dili', name: 'CHC Dili', is_active: true });

    const tenant = await service.findOne('chc-dili');
    expect(tenant.tenant_id).toBe('chc-dili');

    await expect(service.findOne('no-such-tenant')).rejects.toThrow(NotFoundException);
  });

  it('updates name and active state and refreshes updated_at', async () => {
    const repository = (service as unknown as { tenantRepository: { findOne: jest.Mock; save: jest.Mock } }).tenantRepository;
    const original = { tenant_id: 'chc-dili', name: 'CHC Dili', is_active: true, created_at: new Date('2026-01-01T00:00:00Z'), updated_at: new Date('2026-01-01T00:00:00Z') };
    repository.findOne.mockResolvedValueOnce(original);
    // The save mock returns the same object the service mutated, so the old
    // timestamp must be captured before the update call.
    const updatedAtBefore = original.updated_at.getTime();

    const tenant = await service.update('chc-dili', { name: 'CHC Dili Baru', is_active: false });

    expect(tenant.name).toBe('CHC Dili Baru');
    expect(tenant.is_active).toBe(false);
    expect(tenant.updated_at.getTime()).toBeGreaterThan(updatedAtBefore);
  });

  it('reports a missing tenant on update as not found', async () => {
    await expect(service.update('no-such-tenant', { name: 'X' })).rejects.toThrow(NotFoundException);
  });
});
