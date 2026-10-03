import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { TenantRecord } from '../../database/entities/tenant.record';
import { CreateTenantDto, SearchTenantDto, UpdateTenantDto } from './dto/tenant.dto';
import { TenantEntity } from './tenant.entity';

/**
 * Tenant administration.
 *
 * A tenant is a health system that owns facilities. Rows are created only
 * through this administration API (or the Phase 9 migration backfill); there is
 * no bundled seed, mirroring how the medication catalog treats reference data.
 *
 * Suspending a tenant (`is_active = false`) takes effect through
 * `AuthService`: memberships that resolve through the suspended tenant's
 * facilities stop appearing in the authenticated membership list, so the
 * tenant loses every scope at once. Suspension and recovery must therefore be
 * performed by a central authority whose own tenant is still active.
 */
@Injectable()
export class TenantService {
  constructor(
    @InjectRepository(TenantRecord)
    private readonly tenantRepository: Repository<TenantRecord>,
  ) {}

  async create(data: CreateTenantDto): Promise<TenantEntity> {
    const existing = await this.tenantRepository.findOne({ where: { tenant_id: data.tenant_id } });
    if (existing) {
      throw new ConflictException('Tenant identifier already registered.');
    }

    const now = new Date();
    const record = this.tenantRepository.create({
      tenant_id: data.tenant_id,
      name: data.name,
      is_active: true,
      created_at: now,
      updated_at: now,
    });
    return this.toEntity(await this.tenantRepository.save(record));
  }

  async findAll(search: SearchTenantDto = {}): Promise<TenantEntity[]> {
    const query = this.tenantRepository.createQueryBuilder('tenant');
    if (!search.include_inactive) {
      query.andWhere('tenant.is_active = true');
    }
    const records = await query.orderBy('tenant.tenant_id', 'ASC').getMany();
    return records.map((record) => this.toEntity(record));
  }

  async findOne(tenantId: string): Promise<TenantEntity> {
    const record = await this.tenantRepository.findOne({ where: { tenant_id: tenantId } });
    if (!record) throw new NotFoundException('Tenant not found.');
    return this.toEntity(record);
  }

  async update(tenantId: string, data: UpdateTenantDto): Promise<TenantEntity> {
    const record = await this.tenantRepository.findOne({ where: { tenant_id: tenantId } });
    if (!record) throw new NotFoundException('Tenant not found.');

    if (data.name !== undefined) record.name = data.name;
    if (data.is_active !== undefined) record.is_active = data.is_active;
    record.updated_at = new Date();
    return this.toEntity(await this.tenantRepository.save(record));
  }

  private toEntity(record: TenantRecord): TenantEntity {
    return {
      tenant_id: record.tenant_id,
      name: record.name,
      is_active: record.is_active,
      created_at: record.created_at,
      updated_at: record.updated_at,
    };
  }
}
