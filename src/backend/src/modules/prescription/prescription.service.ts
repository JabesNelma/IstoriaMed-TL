import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'node:crypto';
import { DataSource, EntityManager, Repository } from 'typeorm';

import { ClinicalVisitRecord } from '../../database/entities/clinical-visit.record';
import { PrescriptionItemRecord } from '../../database/entities/prescription-item.record';
import { PrescriptionRecord } from '../../database/entities/prescription.record';
import { StaffRecord } from '../../database/entities/staff.record';
import { AuthenticatedUser } from '../auth/auth.types';
import { CreatePrescriptionDto } from './dto/prescription.dto';
import { MedicationService } from './medication.service';
import { PrescriptionEntity, PrescriptionItemEntity } from './prescription.entity';

interface AuthorizedPrescribingContext {
  visit: ClinicalVisitRecord;
  staff: StaffRecord;
  facilityId: string;
  tenantId: string;
}

/** One facility membership as an exact (facility, tenant) authorization pair. */
interface MembershipPair {
  facilityId: string;
  tenantId: string;
}

/**
 * Prescription domain service.
 *
 * Server authority rules (identical in spirit to the Phase 5 clinical visit
 * service):
 *   authenticated user -> verified staff profile -> facility membership ->
 *   clinical visit ownership -> prescription ownership.
 *
 * `prescribed_by_staff_id`, `facility_id` and `tenant_id` are never read from the
 * request. They are derived from the authenticated staff profile and copied from
 * the owning clinical visit, so a prescription can never diverge from the visit
 * it belongs to.
 */
@Injectable()
export class PrescriptionService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly medicationService: MedicationService,
    @InjectRepository(PrescriptionRecord)
    private readonly prescriptionRepository: Repository<PrescriptionRecord>,
    @InjectRepository(PrescriptionItemRecord)
    private readonly prescriptionItemRepository: Repository<PrescriptionItemRecord>,
  ) {}

  /**
   * Creates a prescription together with all of its items in one transaction.
   */
  async create(data: CreatePrescriptionDto, user: AuthenticatedUser): Promise<PrescriptionEntity> {
    return this.dataSource.transaction((manager) => this.createWithinTransaction(manager, data, user));
  }

  /**
   * The shared write path.
   *
   * It runs inside a caller supplied transaction so the offline sync engine can
   * commit a prescription, its items and its sync operation outcome atomically,
   * while reusing this single authorization implementation rather than
   * duplicating the ownership rules.
   *
   * Every medication is resolved and validated before the first insert, so an
   * unknown or inactive medication aborts the whole aggregate and can never leave
   * an orphan prescription or a partial item list behind.
   *
   * `prescriptionId` lets the offline path adopt the canonical identifier the
   * device reserved before it went offline.
   */
  async createWithinTransaction(
    manager: EntityManager,
    data: CreatePrescriptionDto,
    user: AuthenticatedUser,
    prescriptionId?: string,
  ): Promise<PrescriptionEntity> {
    const context = await this.authorize(manager, data.visit_id, user);
    await this.medicationService.resolveActiveMedications(
      data.items.map((item) => item.medication_id),
      manager,
    );

    const now = new Date();
    const record = manager.getRepository(PrescriptionRecord).create({
      prescription_id: prescriptionId ?? randomUUID(),
      visit_id: context.visit.kunjungan_id,
      prescribed_by_staff_id: context.staff.staff_id,
      facility_id: context.facilityId,
      tenant_id: context.tenantId,
      prescribed_at: data.prescribed_at ? new Date(data.prescribed_at) : now,
      notes: data.notes ?? null,
      created_at: now,
      updated_at: now,
    });
    const prescription = await manager.getRepository(PrescriptionRecord).save(record);

    const items = data.items.map((item) =>
      manager.getRepository(PrescriptionItemRecord).create({
        prescription_item_id: randomUUID(),
        prescription_id: prescription.prescription_id,
        medication_id: item.medication_id,
        dose: item.dose,
        frequency: item.frequency,
        route: item.route ?? null,
        duration: item.duration ?? null,
        quantity: item.quantity,
        instructions: item.instructions ?? null,
        created_at: now,
        updated_at: now,
      }),
    );
    await manager.getRepository(PrescriptionItemRecord).save(items);

    return this.toEntity(prescription, items);
  }

  async findAll(user: AuthenticatedUser): Promise<PrescriptionEntity[]> {
    const { pairs } = this.authorizedScope(user);
    if (!pairs.length) return [];
    const scope = this.inAuthorizedScope('prescription', pairs);
    const records = await this.prescriptionRepository
      .createQueryBuilder('prescription')
      .where(scope.sql, scope.parameters)
      .orderBy('prescription.prescribed_at', 'DESC')
      .getMany();
    return this.withItems(records);
  }

  async findOne(id: string, user: AuthenticatedUser): Promise<PrescriptionEntity> {
    const { pairs } = this.authorizedScope(user);
    if (!pairs.length) throw new NotFoundException('Prescription not found.');
    const scope = this.inAuthorizedScope('prescription', pairs);
    const record = await this.prescriptionRepository
      .createQueryBuilder('prescription')
      .where('prescription.prescription_id = :id', { id })
      .andWhere(scope.sql, scope.parameters)
      .getOne();
    // A prescription outside the authorized scope is reported as missing so no
    // information about another facility's records leaks.
    if (!record) throw new NotFoundException('Prescription not found.');
    return this.withItems([record]).then(([entity]) => entity);
  }

  /** Prescriptions belonging to one clinical visit, scoped to the caller. */
  async findByVisit(visitId: string, user: AuthenticatedUser): Promise<PrescriptionEntity[]> {
    const { pairs } = this.authorizedScope(user);
    if (!pairs.length) return [];
    const scope = this.inAuthorizedScope('prescription', pairs);
    const records = await this.prescriptionRepository
      .createQueryBuilder('prescription')
      .where('prescription.visit_id = :visitId', { visitId })
      .andWhere(scope.sql, scope.parameters)
      .orderBy('prescription.prescribed_at', 'ASC')
      .getMany();
    return this.withItems(records);
  }

  /**
   * Resolves the full prescribing authorization chain and returns the values that
   * must be stored on the prescription.
   */
  private async authorize(
    manager: EntityManager,
    visitId: string,
    user: AuthenticatedUser,
  ): Promise<AuthorizedPrescribingContext> {
    const { pairs, tenantIds } = this.authorizedScope(user);

    const visit = await manager.getRepository(ClinicalVisitRecord).findOne({
      where: { kunjungan_id: visitId },
    });
    // A visit that does not exist and a visit owned by another facility are
    // reported identically to avoid disclosing another tenant's records.
    if (!visit) throw new NotFoundException('Clinical visit not found.');

    if (visit.facility_id) {
      // The caller must hold a membership for the exact (facility, tenant) pair
      // that owns the visit. Checking the facility alone would accept a caller
      // whose membership for that facility belongs to a different tenant.
      const ownsVisit = pairs.some(
        (pair) => pair.facilityId === visit.facility_id && pair.tenantId === visit.tenant_id,
      );
      if (!ownsVisit) {
        throw new ForbiddenException('Clinical visit access denied.');
      }
    } else if (!tenantIds.includes(visit.tenant_id)) {
      // Legacy visits may predate facility assignment, so they fall back to a
      // tenant wide check.
      throw new ForbiddenException('Clinical visit access denied.');
    }

    // The prescriber must hold an approved staff profile in the facility that
    // owns the visit, so a prescription can never be signed by staff from a
    // different facility.
    const staffWhere = visit.facility_id
      ? { user_id: user.user_id, facility_id: visit.facility_id, verification_status: 'Approved' as const }
      : { user_id: user.user_id, verification_status: 'Approved' as const };
    const staff = await manager.getRepository(StaffRecord).findOne({ where: staffWhere });
    if (!staff) {
      throw new ForbiddenException('An approved staff profile at the visit facility is required to prescribe.');
    }

    // The prescription facility is the visit facility whenever the visit has one,
    // so the two can never drift apart.
    const facilityId = visit.facility_id ?? staff.facility_id;
    const tenantId = visit.facility_id ? visit.tenant_id : (await this.tenantOfFacility(manager, facilityId) ?? visit.tenant_id);

    return { visit, staff, facilityId, tenantId };
  }

  private async tenantOfFacility(manager: EntityManager, facilityId: string): Promise<string | undefined> {
    const row = (await manager.query('SELECT tenant_id FROM facilities WHERE facility_id = $1', [facilityId])) as
      Array<{ tenant_id: string }>;
    return row[0]?.tenant_id;
  }

  private authorizedScope(user: AuthenticatedUser): { pairs: MembershipPair[]; tenantIds: string[] } {
    return {
      // Memberships are kept as exact (facility, tenant) pairs. Flattening them
      // into two independent lists would let a caller authorized for facility A
      // in tenant X read prescriptions of facility B whenever both facilities
      // happen to share tenant X.
      pairs: [
        ...new Map(
          user.memberships.map((membership) => [
            `${membership.facility_id}|${membership.tenant_id}`,
            { facilityId: membership.facility_id, tenantId: membership.tenant_id },
          ]),
        ).values(),
      ],
      // Only used for legacy visits that predate facility assignment.
      tenantIds: [...new Set(user.memberships.map((membership) => membership.tenant_id))],
    };
  }

  /**
   * Builds a predicate that matches only rows whose facility and tenant both
   * belong to the caller's memberships.
   */
  private inAuthorizedScope(alias: string, pairs: MembershipPair[]): { sql: string; parameters: Record<string, string> } {
    const sql = pairs
      .map((_pair, index) => `(${alias}.facility_id = :facilityId${index} AND ${alias}.tenant_id = :tenantId${index})`)
      .join(' OR ');
    const parameters = Object.fromEntries(
      pairs.flatMap((pair, index) => [
        [`facilityId${index}`, pair.facilityId],
        [`tenantId${index}`, pair.tenantId],
      ]),
    );
    // The whole disjunction is wrapped in parentheses. Without them SQL
    // precedence binds `AND` before `OR`, so a row matching any later branch
    // escapes the `:id` filter and `findOne` silently returns an arbitrary
    // in-scope prescription instead of reporting it as missing.
    return { sql: `(${sql})`, parameters };
  }

  private async withItems(records: PrescriptionRecord[]): Promise<PrescriptionEntity[]> {
    if (!records.length) return [];
    const ids = records.map((record) => record.prescription_id);
    const items = await this.prescriptionItemRepository
      .createQueryBuilder('item')
      .where('item.prescription_id IN (:...ids)', { ids })
      .orderBy('item.created_at', 'ASC')
      .getMany();
    const byPrescription = new Map<string, PrescriptionItemRecord[]>();
    for (const item of items) {
      const bucket = byPrescription.get(item.prescription_id) ?? [];
      bucket.push(item);
      byPrescription.set(item.prescription_id, bucket);
    }
    return records.map((record) => this.toEntity(record, byPrescription.get(record.prescription_id) ?? []));
  }

  private toEntity(record: PrescriptionRecord, items: PrescriptionItemRecord[]): PrescriptionEntity {
    return {
      prescription_id: record.prescription_id,
      visit_id: record.visit_id,
      prescribed_by_staff_id: record.prescribed_by_staff_id,
      facility_id: record.facility_id,
      tenant_id: record.tenant_id,
      prescribed_at: record.prescribed_at,
      notes: record.notes ?? undefined,
      items: items.map((item) => this.toItemEntity(item)),
      created_at: record.created_at,
      updated_at: record.updated_at,
    };
  }

  private toItemEntity(item: PrescriptionItemRecord): PrescriptionItemEntity {
    return {
      prescription_item_id: item.prescription_item_id,
      prescription_id: item.prescription_id,
      medication_id: item.medication_id,
      dose: item.dose,
      frequency: item.frequency,
      route: item.route ?? undefined,
      duration: item.duration ?? undefined,
      quantity: item.quantity,
      instructions: item.instructions ?? undefined,
      created_at: item.created_at,
      updated_at: item.updated_at,
    };
  }
}