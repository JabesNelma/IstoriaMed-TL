import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'node:crypto';
import { EntityManager, Repository } from 'typeorm';

import { MedicationRecord } from '../../database/entities/medication.record';
import { CreateMedicationDto, SearchMedicationDto } from './dto/prescription.dto';
import { MedicationEntity } from './medication.entity';

/**
 * Medication reference catalog.
 *
 * The catalog is shared clinical reference data, not patient data, so it is not
 * tenant or facility scoped and carries no medical history. No national catalog
 * is bundled with this project: rows only exist when they are created through
 * the API, which the tests do with clearly synthetic development data.
 */
@Injectable()
export class MedicationService {
  constructor(
    @InjectRepository(MedicationRecord)
    private readonly medicationRepository: Repository<MedicationRecord>,
  ) {}

  async create(data: CreateMedicationDto): Promise<MedicationEntity> {
    const now = new Date();
    const record = this.medicationRepository.create({
      medication_id: randomUUID(),
      name: data.name,
      generic_name: data.generic_name ?? null,
      form: data.form ?? null,
      strength: data.strength ?? null,
      unit: data.unit ?? null,
      is_active: data.is_active ?? true,
      created_at: now,
      updated_at: now,
    });
    return this.toEntity(await this.medicationRepository.save(record));
  }

  async findAll(search: SearchMedicationDto = {}): Promise<MedicationEntity[]> {
    const query = this.medicationRepository.createQueryBuilder('medication');
    if (!search.include_inactive) {
      query.andWhere('medication.is_active = true');
    }
    if (search.q) {
      // `LOWER(...) LIKE LOWER(...)` is the MySQL/TiDB equivalent of PostgreSQL's
      // `ILIKE`: the comparison is case insensitive whatever collation the column
      // was created with.
      query.andWhere(
        '(LOWER(medication.name) LIKE LOWER(:query) OR LOWER(medication.generic_name) LIKE LOWER(:query))',
        { query: `%${search.q}%` },
      );
    }
    const records = await query.orderBy('medication.name', 'ASC').take(200).getMany();
    return records.map((record) => this.toEntity(record));
  }

  async findOne(id: string): Promise<MedicationEntity> {
    const record = await this.medicationRepository.findOne({ where: { medication_id: id } });
    if (!record) throw new NotFoundException('Medication not found.');
    return this.toEntity(record);
  }

  /**
   * Resolves every requested medication that is prescribable.
   *
   * Returns the found medications keyed by id so the caller can verify the whole
   * set before writing anything. Missing or inactive medications are reported as
   * a single error so the caller can abort the whole transaction.
   *
   * When a transaction `manager` is supplied the lookup joins that transaction,
   * so the validation and the insert observe one consistent database state.
   */
  async resolveActiveMedications(
    medicationIds: string[],
    manager?: EntityManager,
  ): Promise<Map<string, MedicationRecord>> {
    const uniqueIds = [...new Set(medicationIds)];
    if (!uniqueIds.length) return new Map();

    const repository = manager
      ? manager.getRepository(MedicationRecord)
      : this.medicationRepository;
    const records = await repository
      .createQueryBuilder('medication')
      .where('medication.medication_id IN (:...ids)', { ids: uniqueIds })
      .getMany();

    const found = new Map(records.map((record) => [record.medication_id, record]));
    const missing = uniqueIds.filter((id) => !found.has(id));
    if (missing.length) {
      throw new NotFoundException(`Medication not found: ${missing.join(', ')}`);
    }

    const inactive = [...found.values()].filter((record) => !record.is_active);
    if (inactive.length) {
      throw new ForbiddenException(
        `Medication is not active and cannot be prescribed: ${inactive.map((record) => record.name).join(', ')}`,
      );
    }
    return found;
  }

  private toEntity(record: MedicationRecord): MedicationEntity {
    return {
      medication_id: record.medication_id,
      name: record.name,
      generic_name: record.generic_name ?? undefined,
      form: record.form ?? undefined,
      strength: record.strength ?? undefined,
      unit: record.unit ?? undefined,
      is_active: record.is_active,
      created_at: record.created_at,
      updated_at: record.updated_at,
    };
  }
}