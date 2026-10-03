import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import request from 'supertest';
import type { App } from 'supertest/types';
import { randomUUID } from 'node:crypto';

import { AppModule } from '../src/app.module';

/**
 * Phase 7 prescription and medication domain foundation (PostgreSQL e2e).
 *
 * Every scenario uses synthetic development data only. No real patient data is
 * used and no clinical content, token or password hash is logged.
 */
describe('Prescription and medication domain (e2e)', () => {
  let app: INestApplication<App>;
  let database: DataSource;

  let doctorAToken: string;
  let doctorBToken: string;
  let doctorBUserId: string;
  let pharmacyToken: string;
  let unverifiedToken: string;
  let adminToken: string;

  let facilityAId: string;
  let facilityBId: string;
  let staffAId: string;
  let patientAId: string;
  let visitAId: string;
  let medicationAId: string;
  let medicationBId: string;
  let inactiveMedicationId: string;

  const PASSWORD = 'prescription-pass-123';

  async function createApp(): Promise<INestApplication<App>> {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await instance.init();
    return instance;
  }

  async function registerAndLogin(loginIdentifier: string): Promise<{ userId: string; token: string }> {
    const registered = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ login_identifier: loginIdentifier, password: PASSWORD })
      .expect(201);
    const userId = registered.body.user.user_id as string;
    const loggedIn = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ login_identifier: loginIdentifier, password: PASSWORD })
      .expect(201);
    return { userId, token: loggedIn.body.access_token as string };
  }

  async function createFacility(userId: string, code: string, tenant: string, role: string): Promise<string> {
    const facilityId = randomUUID();
    // Phase 9: tenant identity is an authoritative row now, so it must exist
    // before the facility that references it.
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenant],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, 'CHC', $4, NOW(), NOW())`,
      [facilityId, code, code, tenant],
    );
    await database.query(
      `INSERT INTO facility_memberships (membership_id, user_id, facility_id, role, is_active, created_at)
       VALUES ($1, $2, $3, $4, true, NOW())`,
      [randomUUID(), userId, facilityId, role],
    );
    return facilityId;
  }

  async function createStaff(
    userId: string,
    facilityId: string,
    verificationStatus: string,
    profession = 'Doctor',
  ): Promise<string> {
    const staffId = randomUUID();
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
      [staffId, userId, facilityId, `L-${randomUUID()}`, profession, verificationStatus],
    );
    return staffId;
  }

  /** Development/test catalog rows. Clearly synthetic, no real drug data. */
  async function createMedication(name: string, isActive = true): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/admin/medications')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name, generic_name: name, form: 'TABLET', strength: '500 mg', unit: 'TABLET', is_active: isActive })
      .expect(201);
    return response.body.medication_id as string;
  }

  function prescriptionBody(overrides: Record<string, unknown> = {}): Record<string, unknown> {
    return {
      visit_id: visitAId,
      notes: 'Synthetic acceptance prescription',
      items: [
        {
          medication_id: medicationAId,
          dose: '1 tablet',
          frequency: '3x/day',
          route: 'ORAL',
          duration: '5 days',
          quantity: 15,
          instructions: 'Take after food',
        },
      ],
      ...overrides,
    };
  }

  beforeEach(async () => {
    app = await createApp();
    database = app.get(DataSource);

    // Clean in FK-safe order. Prescription history is only removed because this
    // suite owns the whole disposable database.
    await database.query('DELETE FROM prescription_items');
    await database.query('DELETE FROM prescriptions');
    await database.query('DELETE FROM medications');
    await database.query('DELETE FROM sync_operations');
    await database.query('DELETE FROM clinical_visits');
    await database.query('DELETE FROM patients');
    await database.query('DELETE FROM staff_profiles');
    await database.query('DELETE FROM facility_memberships');
    await database.query('DELETE FROM facilities');
    await database.query('DELETE FROM tenants');
    await database.query('DELETE FROM users');

    const suffix = randomUUID();
    const doctorA = await registerAndLogin(`rx-doctor-a-${suffix}@example.com`);
    const doctorB = await registerAndLogin(`rx-doctor-b-${suffix}@example.com`);
    const pharmacy = await registerAndLogin(`rx-pharmacy-${suffix}@example.com`);
    const unverified = await registerAndLogin(`rx-unverified-${suffix}@example.com`);
    const admin = await registerAndLogin(`rx-admin-${suffix}@example.com`);

    doctorAToken = doctorA.token;
    doctorBToken = doctorB.token;
    doctorBUserId = doctorB.userId;
    pharmacyToken = pharmacy.token;
    unverifiedToken = unverified.token;
    adminToken = admin.token;

    facilityAId = await createFacility(doctorA.userId, `A-${suffix}`, `tenant-a-${suffix}`, 'DOCTOR');
    facilityBId = await createFacility(doctorB.userId, `B-${suffix}`, `tenant-b-${suffix}`, 'DOCTOR');
    await createFacility(pharmacy.userId, `P-${suffix}`, `tenant-p-${suffix}`, 'PHARMACY');
    await createFacility(unverified.userId, `U-${suffix}`, `tenant-u-${suffix}`, 'DOCTOR');
    await createFacility(admin.userId, `ADM-${suffix}`, `tenant-adm-${suffix}`, 'SUPER_ADMIN');

    staffAId = await createStaff(doctorA.userId, facilityAId, 'Approved');
    await createStaff(doctorB.userId, facilityBId, 'Approved');
    await createStaff(unverified.userId, facilityBId, 'Pending');

    const patient = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send({
        nama_lengkap: 'Synthetic Acceptance Patient',
        tanggal_lahir: '1988-04-12',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Perempuan',
      })
      .expect(201);
    patientAId = patient.body.data[0].user_id as string;

    const visit = await request(app.getHttpServer())
      .post('/api/istoria-klinis/create')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send({
        pasien_id: patientAId,
        keluhan_subjektif: 'Febre no kabuk manas',
        kode_icd10: 'J06.9',
      })
      .expect(201);
    visitAId = visit.body.kunjungan_id as string;

    medicationAId = await createMedication(`Paracetamol ${suffix}`);
    medicationBId = await createMedication(`Amoxicillin ${suffix}`);
    inactiveMedicationId = await createMedication(`Retired Drug ${suffix}`, false);
  });

  afterEach(async () => app.close());

  // ---------------------------------------------------------------------
  // Test 1
  // ---------------------------------------------------------------------
  it('1. lets authorized medical staff create a prescription and persists the items', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    expect(response.body.prescription_id).toEqual(expect.any(String));
    expect(response.body.visit_id).toBe(visitAId);
    expect(response.body.items).toHaveLength(1);
    expect(response.body.items[0].medication_id).toBe(medicationAId);
    expect(response.body.items[0].quantity).toBe(15);

    const stored = await database.query(
      'SELECT prescription_id, visit_id, prescribed_by_staff_id, facility_id, tenant_id FROM prescriptions WHERE prescription_id = $1',
      [response.body.prescription_id],
    );
    expect(stored).toHaveLength(1);
    expect(stored[0].visit_id).toBe(visitAId);
    expect(stored[0].prescribed_by_staff_id).toBe(staffAId);
    expect(stored[0].facility_id).toBe(facilityAId);

    const items = await database.query(
      'SELECT medication_id, dose, frequency, quantity FROM prescription_items WHERE prescription_id = $1',
      [response.body.prescription_id],
    );
    expect(items).toHaveLength(1);
    expect(items[0].medication_id).toBe(medicationAId);
    expect(items[0].quantity).toBe(15);
  });

  // ---------------------------------------------------------------------
  // Test 2
  // ---------------------------------------------------------------------
  it('2. links the prescription to the correct clinical visit and lists it for that visit', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    const forVisit = await request(app.getHttpServer())
      .get(`/api/prescriptions/visit/${visitAId}`)
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(forVisit.body).toHaveLength(1);
    expect(forVisit.body[0].prescription_id).toBe(created.body.prescription_id);

    const otherVisit = await request(app.getHttpServer())
      .get(`/api/prescriptions/visit/${randomUUID()}`)
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(otherVisit.body).toEqual([]);
  });

  // ---------------------------------------------------------------------
  // Test 3
  // ---------------------------------------------------------------------
  it('3. rejects an invalid medication id', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          items: [{ medication_id: randomUUID(), dose: '1 tablet', frequency: '3x/day', quantity: 5 }],
        }),
      )
      .expect(404);

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          items: [{ medication_id: 'not-a-uuid', dose: '1 tablet', frequency: '3x/day', quantity: 5 }],
        }),
      )
      .expect(400);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 4
  // ---------------------------------------------------------------------
  it('4. rejects an empty or structurally invalid prescription item', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody({ items: [] }))
      .expect(400);

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody({ items: [{ medication_id: medicationAId, frequency: '3x/day', quantity: 5 }] }))
      .expect(400);

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody({ items: [{ medication_id: medicationAId, dose: '   ', frequency: '3x/day', quantity: 5 }] }))
      .expect(400);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 5
  // ---------------------------------------------------------------------
  it('5. rejects zero and negative quantities', async () => {
    for (const quantity of [0, -1, -50]) {
      await request(app.getHttpServer())
        .post('/api/prescriptions')
        .set('Authorization', `Bearer ${doctorAToken}`)
        .send(
          prescriptionBody({
            items: [{ medication_id: medicationAId, dose: '1 tablet', frequency: '3x/day', quantity }],
          }),
        )
        .expect(400);
    }

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 6
  // ---------------------------------------------------------------------
  it('6. rejects an unauthorized role with 403', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${pharmacyToken}`)
      .send(prescriptionBody())
      .expect(403);

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .expect(401);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 7
  // ---------------------------------------------------------------------
  it('7. rejects cross facility prescription creation', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorBToken}`)
      .send(prescriptionBody())
      .expect(403);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 8
  // ---------------------------------------------------------------------
  it('8. rejects cross tenant prescription creation', async () => {
    // A visit in another tenant whose facility the caller does not hold.
    const patientB = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${doctorBToken}`)
      .send({
        nama_lengkap: 'Synthetic Tenant B Patient',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Baucau',
        jenis_kelamin: 'Laki-laki',
      })
      .expect(201);
    const visitB = await request(app.getHttpServer())
      .post('/api/istoria-klinis/create')
      .set('Authorization', `Bearer ${doctorBToken}`)
      .send({ pasien_id: patientB.body.data[0].user_id, keluhan_subjektif: 'Tenant B visit', kode_icd10: 'J06.9' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody({ visit_id: visitB.body.kunjungan_id }))
      .expect(403);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 9
  // ---------------------------------------------------------------------
  it('9. ignores and rejects client attempts to dictate ownership identity', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          prescribed_by_staff_id: randomUUID(),
          facility_id: randomUUID(),
          tenant_id: 'tenant-attacker',
          staf_id: randomUUID(),
        }),
      )
      .expect(400);

    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    // The stored identity is always the server derived one.
    expect(created.body.prescribed_by_staff_id).toBe(staffAId);
    expect(created.body.facility_id).toBe(facilityAId);
    expect(created.body.tenant_id).not.toBe('tenant-attacker');

    const stored = await database.query(
      'SELECT prescribed_by_staff_id, facility_id, tenant_id FROM prescriptions WHERE prescription_id = $1',
      [created.body.prescription_id],
    );
    expect(stored[0].prescribed_by_staff_id).toBe(staffAId);
    expect(stored[0].facility_id).toBe(facilityAId);
    expect(stored[0].tenant_id).not.toBe('tenant-attacker');
  });

  // ---------------------------------------------------------------------
  // Test 10
  // ---------------------------------------------------------------------
  it('10. rolls back the whole aggregate when one item is invalid', async () => {
    const before = await database.query('SELECT count(*)::int AS count FROM prescriptions');

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          items: [
            { medication_id: medicationAId, dose: '1 tablet', frequency: '3x/day', quantity: 15 },
            { medication_id: medicationBId, dose: '1 tablet', frequency: '3x/day', quantity: 10 },
            { medication_id: randomUUID(), dose: '1 tablet', frequency: '3x/day', quantity: 5 },
          ],
        }),
      )
      .expect(404);

    const after = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    const items = await database.query('SELECT count(*)::int AS count FROM prescription_items');
    expect(after[0].count).toBe(before[0].count);
    expect(items[0].count).toBe(0);
  });

  it('10b. rolls back when an item references an inactive medication', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          items: [
            { medication_id: medicationAId, dose: '1 tablet', frequency: '3x/day', quantity: 15 },
            { medication_id: inactiveMedicationId, dose: '1 tablet', frequency: '3x/day', quantity: 5 },
          ],
        }),
      )
      .expect(403);

    const prescriptions = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    const items = await database.query('SELECT count(*)::int AS count FROM prescription_items');
    expect(prescriptions[0].count).toBe(0);
    expect(items[0].count).toBe(0);
  });

  // ---------------------------------------------------------------------
  // Test 11
  // ---------------------------------------------------------------------
  it('11. isolates reads: facility B cannot retrieve a facility A prescription', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    await request(app.getHttpServer())
      .get(`/api/prescriptions/${created.body.prescription_id}`)
      .set('Authorization', `Bearer ${doctorBToken}`)
      .expect(404);

    const list = await request(app.getHttpServer())
      .get('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorBToken}`)
      .expect(200);
    expect(list.body).toEqual([]);

    const byVisit = await request(app.getHttpServer())
      .get(`/api/prescriptions/visit/${visitAId}`)
      .set('Authorization', `Bearer ${doctorBToken}`)
      .expect(200);
    expect(byVisit.body).toEqual([]);
  });

  it('11c. returns 404 for an unknown or out of scope prescription id', async () => {
    // Regression: the authorized scope is a disjunction of membership pairs. If
    // it is not wrapped in parentheses, SQL precedence binds `AND` before `OR`,
    // so the `:id` filter stops applying to the later branches and this
    // endpoint silently returns an arbitrary in-scope prescription for any id.
    // The defect only appears for a caller holding more than one membership
    // pair, because a single pair produces no `OR` at all.
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    // An identifier that does not exist at all must never resolve to a record.
    await request(app.getHttpServer())
      .get(`/api/prescriptions/${randomUUID()}`)
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(404);
    await request(app.getHttpServer())
      .get(`/api/prescriptions/${randomUUID()}`)
      .set('Authorization', `Bearer ${doctorBToken}`)
      .expect(404);

    // Give the doctor a second membership pair so the scope really is a
    // multi-branch disjunction, then prove a bogus id still cannot resolve to
    // the prescription stored under that second pair. The patient, visit and
    // first prescription are created while doctor B still has a single
    // membership, because an ambiguous membership is correctly refused.
    const secondPatient = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${doctorBToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Second Membership Patient',
      tanggal_lahir: '1992-02-02',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Perempuan',
    }).expect(201);
    const secondPatientId = secondPatient.body.data[0].user_id as string;
    const secondVisitId = randomUUID();
    const tenantOfB = await database.query('SELECT tenant_id FROM facilities WHERE facility_id = $1', [facilityBId]);
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'second membership', 'R50.9', NOW(), NOW())`,
      [secondVisitId, secondPatientId, facilityBId, tenantOfB[0].tenant_id],
    );
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorBToken}`)
      .send({ ...prescriptionBody(), visit_id: secondVisitId })
      .expect(201);

    await createFacility(doctorBUserId, `C-${randomUUID()}`, `tenant-${randomUUID()}`, 'DOCTOR');

    const leaked = await request(app.getHttpServer())
      .get(`/api/prescriptions/${randomUUID()}`)
      .set('Authorization', `Bearer ${doctorBToken}`)
      .expect(404);
    expect(leaked.body.prescription_id).toBeUndefined();
  });

  it('11b. refuses a visit whose tenant contradicts its facility', async () => {
    // `clinical_visits.tenant_id` is a plain column, so a migrated or tampered
    // row can name a tenant that contradicts the facility it belongs to. A
    // caller holding a membership for that facility in the other tenant must
    // not be able to prescribe against it, which requires matching the
    // facility and the tenant together rather than the facility alone.
    const foreignTenantVisit = randomUUID();
    // Phase 8 added fk_clinical_visits_facility_tenant, so this contradictory
    // row can no longer be produced by an ordinary INSERT or UPDATE. The check
    // is disabled for one transaction to simulate a row that predates the
    // constraint, because the prescription authorization layer must stay a real
    // defence against legacy or tampered data.
    const runner = database.createQueryRunner();
    await runner.connect();
    await runner.startTransaction();
    await runner.query('SET LOCAL session_replication_role = replica');
    await runner.query(
      `INSERT INTO clinical_visits
         (visit_id, pasien_id, tenant_id, staf_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, 'tenant-that-is-not-mine', $3, NOW(), 'Synthetic inconsistent tenant visit', 'J06.9', NOW(), NOW())`,
      [foreignTenantVisit, patientAId, staffAId],
    );
    // Attach the facility the caller actually belongs to.
    await runner.query('UPDATE clinical_visits SET facility_id = $1 WHERE visit_id = $2', [
      facilityAId,
      foreignTenantVisit,
    ]);
    await runner.commitTransaction();
    await runner.release();

    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody({ visit_id: foreignTenantVisit }))
      .expect(403);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);

    // And the same visit is not readable through the scoped list endpoint.
    const byVisit = await request(app.getHttpServer())
      .get(`/api/prescriptions/visit/${foreignTenantVisit}`)
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(byVisit.body).toEqual([]);
  });

  // ---------------------------------------------------------------------
  // Test 12
  // ---------------------------------------------------------------------
  it('12. keeps the prescription in PostgreSQL after a backend restart', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    await app.close();
    app = await createApp();
    database = app.get(DataSource);

    const stored = await database.query(
      'SELECT prescription_id, visit_id FROM prescriptions WHERE prescription_id = $1',
      [created.body.prescription_id],
    );
    expect(stored).toHaveLength(1);
    expect(stored[0].visit_id).toBe(visitAId);

    const reread = await request(app.getHttpServer())
      .get(`/api/prescriptions/${created.body.prescription_id}`)
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(reread.body.items).toHaveLength(1);
    expect(reread.body.items[0].medication_id).toBe(medicationAId);
  });

  // ---------------------------------------------------------------------
  // Supporting guarantees
  // ---------------------------------------------------------------------
  it('requires an approved staff profile at the visit facility', async () => {
    await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${unverifiedToken}`)
      .send(prescriptionBody())
      .expect(403);

    const count = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(count[0].count).toBe(0);
  });

  it('never lets a prescription be deleted through the medication relationship', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(prescriptionBody())
      .expect(201);

    // Medication rows referenced by a prescription are protected by RESTRICT.
    await expect(database.query('DELETE FROM medications WHERE medication_id = $1', [medicationAId])).rejects.toThrow();
    // The visit that owns the prescription is protected too.
    await expect(database.query('DELETE FROM clinical_visits WHERE visit_id = $1', [visitAId])).rejects.toThrow();
    // And a prescription that still owns items cannot be removed.
    await expect(
      database.query('DELETE FROM prescriptions WHERE prescription_id = $1', [created.body.prescription_id]),
    ).rejects.toThrow();
    // A patient that still owns a clinical visit is protected as well, so the
    // whole clinical chain is erasure proof from the bottom up.
    await expect(database.query('DELETE FROM patients WHERE patient_id = $1', [patientAId])).rejects.toThrow();

    const still = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(still[0].count).toBe(1);
  });

  it('serves the medication catalog without leaking patient data', async () => {
    const asDoctor = await request(app.getHttpServer())
      .get('/api/medications')
      .query({ q: 'Paracetamol' })
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(asDoctor.body.length).toBeGreaterThanOrEqual(1);

    // Pharmacy may read the catalog even though it may not prescribe.
    const asPharmacy = await request(app.getHttpServer())
      .get('/api/medications')
      .set('Authorization', `Bearer ${pharmacyToken}`)
      .expect(200);
    expect(asPharmacy.body.length).toBeGreaterThan(0);

    // Inactive medications are hidden by default.
    const inactive = await request(app.getHttpServer())
      .get('/api/medications')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(inactive.body.map((row: { medication_id: string }) => row.medication_id)).not.toContain(
      inactiveMedicationId,
    );
  });

  it('accepts the boolean include_inactive query parameter as a string', async () => {
    // Query parameters arrive as strings, so this must not fail validation.
    const explicitFalse = await request(app.getHttpServer())
      .get('/api/medications')
      .query({ include_inactive: 'false' })
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(explicitFalse.body.map((row: { medication_id: string }) => row.medication_id)).not.toContain(
      inactiveMedicationId,
    );

    const explicitTrue = await request(app.getHttpServer())
      .get('/api/medications')
      .query({ include_inactive: 'true' })
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(200);
    expect(explicitTrue.body.map((row: { medication_id: string }) => row.medication_id)).toContain(
      inactiveMedicationId,
    );

    // A non boolean value is rejected rather than silently coerced.
    await request(app.getHttpServer())
      .get('/api/medications')
      .query({ include_inactive: 'maybe' })
      .set('Authorization', `Bearer ${doctorAToken}`)
      .expect(400);
  });

  it('restricts medication catalog creation to administrative roles', async () => {
    await request(app.getHttpServer())
      .post('/api/admin/medications')
      .set('Authorization', `Bearer ${pharmacyToken}`)
      .send({ name: 'Unauthorized catalog row' })
      .expect(403);

    await request(app.getHttpServer())
      .post('/api/admin/medications')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send({ name: 'Unauthorized catalog row' })
      .expect(403);

    const count = await database.query(
      "SELECT count(*)::int AS count FROM medications WHERE name = 'Unauthorized catalog row'",
    );
    expect(count[0].count).toBe(0);
  });

  it('creates several items for one prescription', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(
        prescriptionBody({
          items: [
            { medication_id: medicationAId, dose: '1 tablet', frequency: '3x/day', route: 'ORAL', duration: '5 days', quantity: 15, instructions: 'Take after food' },
            { medication_id: medicationBId, dose: '1 capsule', frequency: '2x/day', route: 'ORAL', duration: '7 days', quantity: 14, instructions: 'Take with water' },
          ],
        }),
      )
      .expect(201);

    expect(created.body.items).toHaveLength(2);
    const items = await database.query(
      'SELECT count(*)::int AS count FROM prescription_items WHERE prescription_id = $1',
      [created.body.prescription_id],
    );
    expect(items[0].count).toBe(2);
  });

  // ---------------------------------------------------------------------
  // Phase 6 offline sync integration
  // ---------------------------------------------------------------------
  function prescriptionOperation(prescriptionId: string): Record<string, unknown> {
    return {
      operation: {
        operation_id: randomUUID(),
        entity_type: 'PRESCRIPTION',
        operation_type: 'CREATE',
        entity_id: prescriptionId,
        payload: {
          prescription_id: prescriptionId,
          visit_id: visitAId,
          notes: 'Synthetic offline prescription',
          items: [
            {
              medication_id: medicationAId,
              dose: '1 tablet',
              frequency: '3x/day',
              route: 'ORAL',
              duration: '5 days',
              quantity: 15,
              instructions: 'Take after food',
            },
          ],
        },
      },
    };
  }

  it('syncs an offline prescription adopting the identifier the device reserved', async () => {
    const reservedId = randomUUID();
    const body = prescriptionOperation(reservedId);

    const response = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);

    expect(response.body.status).toBe('SYNCED');
    expect(response.body.entity_id).toBe(reservedId);
    expect(response.body.entity.item_count).toBe(1);

    const stored = await database.query(
      'SELECT visit_id, prescribed_by_staff_id, facility_id FROM prescriptions WHERE prescription_id = $1',
      [reservedId],
    );
    expect(stored).toHaveLength(1);
    expect(stored[0].visit_id).toBe(visitAId);
    // The identity is still derived on the server for the offline path.
    expect(stored[0].prescribed_by_staff_id).toBe(staffAId);
    expect(stored[0].facility_id).toBe(facilityAId);

    const items = await database.query(
      'SELECT count(*)::int AS count FROM prescription_items WHERE prescription_id = $1',
      [reservedId],
    );
    expect(items[0].count).toBe(1);
  });

  it('keeps an offline prescription idempotent when the same operation is replayed', async () => {
    const reservedId = randomUUID();
    const body = prescriptionOperation(reservedId);

    const first = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);
    expect(first.body.status).toBe('SYNCED');

    const replay = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);
    expect(replay.body.status).toBe('SYNCED');

    const prescriptions = await database.query(
      'SELECT count(*)::int AS count FROM prescriptions WHERE prescription_id = $1',
      [reservedId],
    );
    const items = await database.query(
      'SELECT count(*)::int AS count FROM prescription_items WHERE prescription_id = $1',
      [reservedId],
    );
    expect(prescriptions[0].count).toBe(1);
    expect(items[0].count).toBe(1);
  });

  it('never lets an offline payload dictate its own ownership identity', async () => {
    const reservedId = randomUUID();
    const body = prescriptionOperation(reservedId);
    (body.operation.payload as Record<string, unknown>).facility_id = randomUUID();
    (body.operation.payload as Record<string, unknown>).prescribed_by_staff_id = randomUUID();
    (body.operation.payload as Record<string, unknown>).tenant_id = 'tenant-attacker';

    // The sync contract treats ownership fields as protected, so the operation
    // is recorded as FAILED rather than silently accepting the forged identity.
    const response = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);

    expect(response.body.status).toBe('FAILED');

    const prescriptions = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    expect(prescriptions[0].count).toBe(0);
  });

  it('writes nothing when an offline prescription references an unknown medication', async () => {
    const body = prescriptionOperation(randomUUID());
    const items = body.operation.payload as { items: Array<Record<string, unknown>> };
    items.items = [
      { medication_id: medicationAId, dose: '1 tablet', frequency: '3x/day', quantity: 15 },
      { medication_id: randomUUID(), dose: '1 tablet', frequency: '3x/day', quantity: 5 },
    ];

    const response = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);

    expect(response.body.status).toBe('FAILED');

    // The aggregate rolled back completely: no orphan prescription, no partial
    // item list, and no operation falsely marked as synced.
    const prescriptions = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    const prescriptionItems = await database.query('SELECT count(*)::int AS count FROM prescription_items');
    expect(prescriptions[0].count).toBe(0);
    expect(prescriptionItems[0].count).toBe(0);

    const operation = await database.query('SELECT status FROM sync_operations WHERE operation_id = $1', [
      body.operation.operation_id as string,
    ]);
    expect(operation[0].status).toBe('FAILED');
  });

  it('refuses to sync an offline prescription against a visit that does not exist', async () => {
    const body = prescriptionOperation(randomUUID());
    (body.operation.payload as Record<string, unknown>).visit_id = randomUUID();

    const response = await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send(body)
      .expect(201);

    // A missing visit must fail permanently instead of orphaning a prescription.
    expect(response.body.status).toBe('FAILED');

    const prescriptions = await database.query('SELECT count(*)::int AS count FROM prescriptions');
    const prescriptionItems = await database.query('SELECT count(*)::int AS count FROM prescription_items');
    expect(prescriptions[0].count).toBe(0);
    expect(prescriptionItems[0].count).toBe(0);
  });
});