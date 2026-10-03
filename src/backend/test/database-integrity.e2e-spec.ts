import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';

/**
 * Phase 8 - Database integrity and multi-facility foundation.
 *
 * These tests assert database level guarantees only. The multi facility
 * authorization behaviour (that belonging to one facility must not imply access
 * to a sibling facility in the same tenant) lives in security.e2e-spec.ts,
 * because that is an HTTP authorization concern rather than a constraint.
 */
describe('Database integrity and multi-facility foundation (e2e)', () => {
  let app: INestApplication;
  let database: DataSource;
  const tenant = () => `tenant-${randomUUID()}`;

  async function createFacility(code: string, tenantId: string): Promise<string> {
    const facilityId = randomUUID();
    // Phase 9: tenant identity is an authoritative row now, so it must exist
    // before the facility that references it.
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenantId],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, 'CHC', $4, NOW(), NOW())`,
      [facilityId, code, code, tenantId],
    );
    return facilityId;
  }

  async function createUser(login: string): Promise<string> {
    const userId = randomUUID();
    await database.query(
      `INSERT INTO users (user_id, login_identifier, password_hash, is_active, created_at, updated_at)
       VALUES ($1, $2, 'hash', true, NOW(), NOW())`,
      [userId, login],
    );
    return userId;
  }

  async function createStaff(userId: string, facilityId: string): Promise<string> {
    const staffId = randomUUID();
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [staffId, userId, facilityId, `LIC-${randomUUID()}`],
    );
    return staffId;
  }

  async function createPatient(facilityId: string): Promise<string> {
    const patientId = randomUUID();
    await database.query(
      `INSERT INTO patients (patient_id, medical_record_number, nama_lengkap, tanggal_lahir, tempat_lahir,
                             jenis_kelamin, created_at, updated_at, facility_id)
       VALUES ($1, $2, 'Integrity Patient', '1990-01-01', 'Dili', 'Laki-laki', NOW(), NOW(), $3)`,
      [patientId, `MRN-${randomUUID()}`, facilityId],
    );
    return patientId;
  }

  async function createVisit(
    patientId: string,
    facilityId: string | null,
    tenantId: string,
    staffId: string | null,
  ): Promise<string> {
    const visitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, staf_id, visit_date,
                                    keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW(), 'integrity visit', 'R50.9', NOW(), NOW())`,
      [visitId, patientId, facilityId, tenantId, staffId],
    );
    return visitId;
  }

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();
    database = app.get(DataSource);
    // Phase 8: clinical_visits now RESTRICT staff_profiles, and both RESTRICT
    // facilities, so children must be cleared before their parents. Phase 9:
    // tenants RESTRICT their facilities too, so they clear last.
    await database.query('DELETE FROM prescription_items');
    await database.query('DELETE FROM prescriptions');
    await database.query('DELETE FROM medications');
    await database.query('DELETE FROM clinical_visits');
    await database.query('DELETE FROM patients');
    await database.query('DELETE FROM staff_profiles');
    await database.query('DELETE FROM facility_memberships');
    await database.query('DELETE FROM facilities');
    await database.query('DELETE FROM tenants');
    await database.query('DELETE FROM users');
  });

  // `?.` keeps a failed bootstrap from masking the real error with an
  // unrelated "cannot read properties of undefined" from this hook.
  afterEach(async () => app?.close());

  it('lets one tenant own several facilities at the same time', async () => {
    const sharedTenant = tenant();
    // This pair of inserts could not coexist while facilities.tenant_id carried
    // a UNIQUE constraint, so the assertion is a real Phase 8 regression guard.
    const first = await createFacility(`MF1-${randomUUID()}`, sharedTenant);
    const second = await createFacility(`MF2-${randomUUID()}`, sharedTenant);

    const rows = await database.query('SELECT facility_id FROM facilities WHERE tenant_id = $1 ORDER BY facility_id', [
      sharedTenant,
    ]);
    expect(rows).toHaveLength(2);
    expect(rows.map((row) => row.facility_id).sort()).toEqual([first, second].sort());
  });

  it('keeps a non unique lookup index on facilities.tenant_id', async () => {
    const constraints = await database.query(
      `SELECT conname FROM pg_constraint WHERE conrelid = 'facilities'::regclass AND contype = 'u'`,
    );
    const uniqueColumns = constraints.map((row) => row.conname);
    expect(uniqueColumns).not.toContain('facilities_tenant_id_key');

    const indexes = await database.query(
      `SELECT indexname FROM pg_indexes WHERE tablename = 'facilities' AND indexname = 'idx_facilities_tenant_id'`,
    );
    expect(indexes).toHaveLength(1);
  });

  it('accepts a clinical visit that references a real staff profile', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`S1-${randomUUID()}`, tenantId);
    const staffId = await createStaff(await createUser('staff-ok@example.com'), facilityId);
    const patientId = await createPatient(facilityId);

    await expect(createVisit(patientId, facilityId, tenantId, staffId)).resolves.toEqual(expect.any(String));

    const stored = await database.query('SELECT staf_id FROM clinical_visits WHERE pasien_id = $1', [patientId]);
    expect(stored[0].staf_id).toBe(staffId);
  });

  it('rejects a clinical visit that references a nonexistent staff profile', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`S2-${randomUUID()}`, tenantId);
    const patientId = await createPatient(facilityId);

    await expect(createVisit(patientId, facilityId, tenantId, randomUUID())).rejects.toThrow(/fk_clinical_visits_staf/);
    const stored = await database.query('SELECT count(*)::int AS count FROM clinical_visits WHERE pasien_id = $1', [
      patientId,
    ]);
    expect(stored[0].count).toBe(0);
  });

  it('refuses to delete a staff profile that a clinical visit still references', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`S3-${randomUUID()}`, tenantId);
    const staffId = await createStaff(await createUser('staff-restrict@example.com'), facilityId);
    const patientId = await createPatient(facilityId);
    await createVisit(patientId, facilityId, tenantId, staffId);

    await expect(database.query('DELETE FROM staff_profiles WHERE staff_id = $1', [staffId])).rejects.toThrow(
      /fk_clinical_visits_staf/,
    );

    // RESTRICT, never CASCADE: the clinical visit and the staff row both survive.
    const staff = await database.query('SELECT count(*)::int AS count FROM staff_profiles WHERE staff_id = $1', [
      staffId,
    ]);
    const visits = await database.query('SELECT count(*)::int AS count FROM clinical_visits WHERE pasien_id = $1', [
      patientId,
    ]);
    expect(staff[0].count).toBe(1);
    expect(visits[0].count).toBe(1);
  });

  it('rejects a clinical visit whose tenant contradicts its facility', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`P1-${randomUUID()}`, tenantId);
    const patientId = await createPatient(facilityId);

    await expect(createVisit(patientId, facilityId, tenant(), null)).rejects.toThrow(
      /fk_clinical_visits_facility_tenant/,
    );
  });

  it('rejects a prescription whose tenant contradicts its facility', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`P2-${randomUUID()}`, tenantId);
    const userId = await createUser('rx-pair@example.com');
    const staffId = await createStaff(userId, facilityId);
    const patientId = await createPatient(facilityId);
    await createVisit(patientId, facilityId, tenantId, staffId);
    const visitId = await database.query('SELECT visit_id FROM clinical_visits WHERE pasien_id = $1', [patientId]).then(
      (rows) => rows[0].visit_id as string,
    );

    await expect(
      database.query(
        `INSERT INTO prescriptions (prescription_id, visit_id, prescribed_by_staff_id, facility_id, tenant_id,
                                   prescribed_at, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, NOW(), NOW(), NOW())`,
        [randomUUID(), visitId, staffId, facilityId, `tenant-${randomUUID()}`],
      ),
    ).rejects.toThrow(/fk_prescriptions_facility_tenant/);
  });

  it('still accepts a legacy clinical visit that has no facility', async () => {
    const tenantId = tenant();
    const facilityId = await createFacility(`L1-${randomUUID()}`, tenantId);
    const patientId = await createPatient(facilityId);

    // MATCH SIMPLE composite keys are not enforced when any column is NULL, so
    // pre facility rows keep working instead of forcing a backfill.
    await expect(createVisit(patientId, null, tenantId, null)).resolves.toEqual(expect.any(String));
  });

  it('creates no cascade anywhere in the clinical schema', async () => {
    const unsafe = await database.query(
      `SELECT conname FROM pg_constraint
       WHERE contype = 'f' AND connamespace = 'public'::regnamespace
         AND confdeltype IN ('c', 'n')`,
    );
    expect(unsafe).toHaveLength(0);
  });
});