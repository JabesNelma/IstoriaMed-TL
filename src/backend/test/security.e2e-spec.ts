import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import type { App } from 'supertest/types';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';

describe('Authentication and facility authorization (e2e)', () => {
  let app: INestApplication<App>;
  let database: DataSource;
  let userAToken: string;
  let userBToken: string;
  let pharmacyToken: string;
  let tenantA: string;
  let tenantB: string;
  let facilityAId: string;
  let userAId: string;

  async function createApp() {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await instance.init();
    return instance;
  }

  async function addFacilityMembership(userId: string, code: string, tenant: string, role: string) {
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

  beforeEach(async () => {
    app = await createApp();
    database = app.get(DataSource);
    // Phase 7: prescriptions RESTRICT their visit, staff and medication
    // references, so clinical records must be cleared children first.
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

    const userA = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'a@example.com', password: 'password-a-123' }).expect(201);
    const userB = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'b@example.com', password: 'password-b-123' }).expect(201);
    const pharmacy = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'pharmacy@example.com', password: 'password-p-123' }).expect(201);
    tenantA = `tenant-${randomUUID()}`;
    tenantB = `tenant-${randomUUID()}`;
    userAId = userA.body.user.user_id as string;
    facilityAId = await addFacilityMembership(userAId, `A-${randomUUID()}`, tenantA, 'DOCTOR');
    const facilityBId = await addFacilityMembership(userB.body.user.user_id, `B-${randomUUID()}`, tenantB, 'DOCTOR');
    await addFacilityMembership(pharmacy.body.user.user_id, `P-${randomUUID()}`, `tenant-${randomUUID()}`, 'PHARMACY');
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [randomUUID(), userA.body.user.user_id, facilityAId, `A-${randomUUID()}`],
    );
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [randomUUID(), userB.body.user.user_id, facilityBId, `B-${randomUUID()}`],
    );
    userAToken = (await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'a@example.com', password: 'password-a-123' }).expect(201)).body.access_token as string;
    userBToken = (await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'b@example.com', password: 'password-b-123' }).expect(201)).body.access_token as string;
    pharmacyToken = await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'pharmacy@example.com', password: 'password-p-123' }).then((response) => response.body.access_token);
  });

  afterEach(async () => app.close());

  it('accepts valid login and rejects wrong credentials', async () => {
    expect(userAToken).toEqual(expect.any(String));
    await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'a@example.com', password: 'wrong-password' }).expect(401);
    await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'missing@example.com', password: 'password-a-123' }).expect(401);
    const stored = await database.query('SELECT password_hash FROM users WHERE login_identifier = $1', ['a@example.com']);
    expect(stored[0].password_hash).toMatch(/^\$argon2/);
    const loginResponse = await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'a@example.com', password: 'password-a-123' }).expect(201);
    expect(loginResponse.body.user.password_hash).toBeUndefined();
  });

  it('rejects inactive, invalid, and expired tokens', async () => {
    await database.query('UPDATE users SET is_active = false WHERE login_identifier = $1', ['a@example.com']);
    await request(app.getHttpServer()).post('/api/auth/login').send({ login_identifier: 'a@example.com', password: 'password-a-123' }).expect(401);
    await request(app.getHttpServer()).get('/api/pasien').set('Authorization', 'Bearer invalid.token.value').expect(401);
    const expired = await app.get(JwtService).signAsync({ sub: '00000000-0000-0000-0000-000000000001', login_identifier: 'expired@example.com' }, { expiresIn: -1 });
    await request(app.getHttpServer()).get('/api/pasien').set('Authorization', `Bearer ${expired}`).expect(401);
  });

  it('requires a token and a clinical role', async () => {
    await request(app.getHttpServer()).get('/api/pasien').expect(401);
    await request(app.getHttpServer()).get('/api/pasien').set('Authorization', `Bearer ${pharmacyToken}`).expect(403);
  });

  it('does not allow a user to access another facility tenant', async () => {
    const patientB = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userBToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Facility B Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }).expect(201);
    const patientBId = patientB.body.data[0].user_id as string;
    await request(app.getHttpServer()).get('/api/pasien').query({ q: 'Facility B Patient' }).set('Authorization', `Bearer ${userAToken}`).expect(200).expect([]);
    await request(app.getHttpServer()).get(`/api/pasien/${patientBId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/tenant/${tenantB}`).set('Authorization', `Bearer ${userAToken}`).expect(403);
    await request(app.getHttpServer()).post('/api/istoria-klinis/create').set('Authorization', `Bearer ${userAToken}`).send({
      pasien_id: '00000000-0000-0000-0000-000000000000',
      tenant_id: tenantB,
      keluhan_subjektif: 'forbidden',
      kode_icd10: 'R50.9',
    }).expect(403);
  });

  it('isolates clinical visits by exact facility and tenant pair', async () => {
    // Phase 7.1 regression: the clinical visit service previously matched
    // `facility_id IN (...) OR tenant_id IN (...)`. That is not pair safe, so a
    // visit whose `tenant_id` column contradicts the tenant that actually owns
    // its facility was readable and editable by every member of that tenant.
    const facilityOfB = await database.query('SELECT facility_id FROM facilities WHERE tenant_id = $1', [tenantB]);
    const facilityBId = facilityOfB[0].facility_id as string;

    const patientB = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userBToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Visit Isolation Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }).expect(201);
    const patientBId = patientB.body.data[0].user_id as string;

    // Facility B owns tenant B; the tenant_id column deliberately claims
    // tenant A, the state a migrated or tampered row can produce.
    //
    // Phase 8 added fk_clinical_visits_facility_tenant, which makes this exact
    // row impossible to create through the database. The reference check is
    // switched off for this one transaction so the test still exercises the
    // authorization layer against rows that predate the constraint, for example
    // data migrated before Phase 8. The authorization fix must remain a real
    // defence, so it is deliberately not deleted.
    //
    // SET LOCAL keeps this on a single pooled connection and it is undone by
    // COMMIT, so no other test can observe a weakened constraint.
    const runner = database.createQueryRunner();
    await runner.connect();
    await runner.startTransaction();
    const mismatchedVisitId = randomUUID();
    await runner.query('SET LOCAL session_replication_role = replica');
    await runner.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'facility B record', 'R50.9', NOW(), NOW())`,
      [mismatchedVisitId, patientBId, facilityBId, tenantA],
    );
    await runner.commitTransaction();
    await runner.release();

    // Read isolation across every clinical visit surface.
    const list = await request(app.getHttpServer()).get('/api/istoria-klinis').set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect((list.body as Array<{ kunjungan_id: string }>).map((visit) => visit.kunjungan_id)).not.toContain(mismatchedVisitId);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/${mismatchedVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    // Patient history for another facility's patient is refused outright, because
    // the patient itself is outside the authorized scope.
    await request(app.getHttpServer()).get(`/api/istoria-klinis/pasien/${patientBId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    const byTenant = await request(app.getHttpServer()).get(`/api/istoria-klinis/tenant/${tenantA}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect((byTenant.body as Array<{ kunjungan_id: string }>).map((visit) => visit.kunjungan_id)).not.toContain(mismatchedVisitId);

    // Write isolation: a cross tenant edit of another facility's record must be
    // refused. This is the severe case because it corrupted clinical content.
    await request(app.getHttpServer())
      .patch(`/api/istoria-klinis/${mismatchedVisitId}`)
      .set('Authorization', `Bearer ${userAToken}`)
      .send({ keluhan_subjektif: 'tampered' })
      .expect(403);
    const untouched = await database.query('SELECT keluhan_subjektif FROM clinical_visits WHERE visit_id = $1', [mismatchedVisitId]);
    expect(untouched[0].keluhan_subjektif).toBe('facility B record');
  });

  it('resolves a clinical visit by its identifier', async () => {
    // Regression: the authorized scope is an OR disjunction of membership pairs
    // plus a legacy branch. Without surrounding parentheses SQL binds `AND`
    // before `OR`, so the `:id` filter is dropped from every branch but the
    // first and this endpoint returns an arbitrary in-scope record for any id.
    // The caller therefore needs more than one scope branch for the defect to
    // be observable, which is why a second membership is added here.
    const ownPatient = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userAToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Own Facility Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }).expect(201);
    const patientId = ownPatient.body.data[0].user_id as string;

    const ownVisitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'own record', 'R50.9', NOW(), NOW())`,
      [ownVisitId, patientId, facilityAId, tenantA],
    );

    // A second membership pair, so the scope really is a multi-branch
    // disjunction rather than a single conjunction.
    const tenantD = `tenant-${randomUUID()}`;
    const facilityDId = await addFacilityMembership(userAId, `D-${randomUUID()}`, tenantD, 'DOCTOR');
    const secondVisitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'second membership', 'R50.9', NOW(), NOW())`,
      [secondVisitId, patientId, facilityDId, tenantD],
    );

    // A legacy visit with no facility, which adds the third scope branch.
    const legacyVisitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, NULL, $3, NOW(), 'legacy record', 'R50.9', NOW(), NOW())`,
      [legacyVisitId, patientId, tenantA],
    );

    // Each identifier must resolve to exactly its own record.
    const own = await request(app.getHttpServer()).get(`/api/istoria-klinis/${ownVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect(own.body.kunjungan_id).toBe(ownVisitId);
    expect(own.body.keluhan_subjektif).toBe('own record');
    const second = await request(app.getHttpServer()).get(`/api/istoria-klinis/${secondVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect(second.body.kunjungan_id).toBe(secondVisitId);
    const legacy = await request(app.getHttpServer()).get(`/api/istoria-klinis/${legacyVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect(legacy.body.kunjungan_id).toBe(legacyVisitId);

    // An identifier that does not exist must never resolve to any of them.
    for (let attempt = 0; attempt < 5; attempt += 1) {
      await request(app.getHttpServer()).get(`/api/istoria-klinis/${randomUUID()}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    }
  });

  it('does not trust a client-supplied tenant identifier', async () => {
    await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userAToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Scoped Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
      tenant_id: tenantB,
    }).expect(400);
  });

  it('lets one tenant hold two facilities and still keeps them isolated', async () => {
    // Phase 8: a tenant may own many facilities. Sharing the tenant must never
    // become a shortcut into a sibling facility the caller has no membership in.
    const siblingFacilityId = randomUUID();
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenantA],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, 'Sibling Facility', 'CHC', $3, NOW(), NOW())`,
      [siblingFacilityId, `SIB-${randomUUID()}`, tenantA],
    );

    const siblingStaffId = randomUUID();
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [siblingStaffId, userAId, siblingFacilityId, `SIB-${randomUUID()}`],
    );

    const siblingPatient = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userAToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Sibling Facility Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }).expect(201);
    const siblingPatientId = siblingPatient.body.data[0].user_id as string;

    // Move that patient and its visit into the sibling facility. The pair stays
    // valid for tenant A, so only the authorization layer can refuse access.
    await database.query('UPDATE patients SET facility_id = $1 WHERE patient_id = $2', [siblingFacilityId, siblingPatientId]);
    const siblingVisitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, staf_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW(), 'sibling facility visit', 'R50.9', NOW(), NOW())`,
      [siblingVisitId, siblingPatientId, siblingFacilityId, tenantA, siblingStaffId],
    );

    // Same tenant, different facility, no membership: denied on every surface.
    await request(app.getHttpServer()).get(`/api/pasien/${siblingPatientId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/${siblingVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    const list = await request(app.getHttpServer()).get('/api/istoria-klinis').set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect((list.body as Array<{ kunjungan_id: string }>).map((visit) => visit.kunjungan_id)).not.toContain(siblingVisitId);

    // The tenant wide route is still tenant scoped, so it must also hide the
    // visit of a facility the caller does not belong to.
    const byTenant = await request(app.getHttpServer()).get(`/api/istoria-klinis/tenant/${tenantA}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect((byTenant.body as Array<{ kunjungan_id: string }>).map((visit) => visit.kunjungan_id)).not.toContain(siblingVisitId);

    // Granting the explicit membership is what makes it visible, proving the
    // decision is driven by the pair and not by the shared tenant.
    await database.query(
      `INSERT INTO facility_memberships (membership_id, user_id, facility_id, role, is_active, created_at)
       VALUES ($1, $2, $3, 'DOCTOR', true, NOW())`,
      [randomUUID(), userAId, siblingFacilityId],
    );
    const granted = await request(app.getHttpServer()).get(`/api/istoria-klinis/${siblingVisitId}`).set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect(granted.body.kunjungan_id).toBe(siblingVisitId);
  });

  it('denies cross tenant access to a sibling facility of another tenant', async () => {
    // Phase 8: tenant B now has a second facility, and none of it may leak to
    // a tenant A caller even though facility codes look interchangeable.
    const otherTenantFacilityId = randomUUID();
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenantB],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, 'Tenant B Second Facility', 'CHC', $3, NOW(), NOW())`,
      [otherTenantFacilityId, `B2-${randomUUID()}`, tenantB],
    );

    const facilityBId = await database.query('SELECT facility_id FROM facilities WHERE tenant_id = $1 AND facility_id <> $2', [
      tenantB,
      otherTenantFacilityId,
    ]).then((rows) => rows[0].facility_id as string);

    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [randomUUID(), userAId, otherTenantFacilityId, `B2L-${randomUUID()}`],
    );

    const patientId = randomUUID();
    await database.query(
      `INSERT INTO patients (patient_id, medical_record_number, nama_lengkap, tanggal_lahir, tempat_lahir,
                             jenis_kelamin, created_at, updated_at, facility_id)
       VALUES ($1, $2, 'Tenant B Patient', '1990-01-01', 'Dili', 'Laki-laki', NOW(), NOW(), $3)`,
      [patientId, `MRN-${randomUUID()}`, otherTenantFacilityId],
    );
    const visitId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'tenant b visit', 'R50.9', NOW(), NOW())`,
      [visitId, patientId, otherTenantFacilityId, tenantB],
    );

    // Sanity check: tenant B really does own two facilities side by side now.
    const tenantBFacilities = await database.query('SELECT facility_id FROM facilities WHERE tenant_id = $1', [tenantB]);
    expect(tenantBFacilities).toHaveLength(2);
    expect(tenantBFacilities.map((row) => row.facility_id)).toContain(otherTenantFacilityId);
    expect(tenantBFacilities.map((row) => row.facility_id)).toContain(facilityBId);

    // A tenant A caller is refused by detail, by patient history and by list.
    await request(app.getHttpServer()).get(`/api/istoria-klinis/${visitId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/pasien/${patientId}`).set('Authorization', `Bearer ${userAToken}`).expect(404);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/tenant/${tenantB}`).set('Authorization', `Bearer ${userAToken}`).expect(403);
    const list = await request(app.getHttpServer()).get('/api/istoria-klinis').set('Authorization', `Bearer ${userAToken}`).expect(200);
    expect((list.body as Array<{ kunjungan_id: string }>).map((visit) => visit.kunjungan_id)).not.toContain(visitId);
  });

  it('refuses a forged facility and tenant pair supplied by a client', async () => {
    // Phase 8 / section 24: manufacturing "facility A plus tenant B" must not
    // resolve, on any surface, even though each half is individually real.
    const facilityBId = await database.query('SELECT facility_id FROM facilities WHERE tenant_id = $1', [tenantB]).then(
      (rows) => rows[0].facility_id as string,
    );
    const patientB = await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${userBToken}`).send({
      no_ktp: null,
      nama_lengkap: 'Pair Forgery Patient',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Laki-laki',
    }).expect(201);
    const patientBId = patientB.body.data[0].user_id as string;
    const visitBId = randomUUID();
    await database.query(
      `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), 'tenant b visit', 'R50.9', NOW(), NOW())`,
      [visitBId, patientBId, facilityBId, tenantB],
    );

// A tenant A caller naming tenant B in the body is refused. The patient does
    // exist but sits outside the caller's facility scope, so creation answers
    // 403 rather than silently attributing the visit to the caller's facility.
    await request(app.getHttpServer()).post('/api/istoria-klinis/create').set('Authorization', `Bearer ${userAToken}`).send({
      pasien_id: patientBId,
      tenant_id: tenantB,
      keluhan_subjektif: 'forged pair',
      kode_icd10: 'R50.9',
    }).expect(403);

    // facility_id is not part of the create contract at all. The validation pipe
    // strips it before the service runs, so a caller cannot steer ownership by
    // naming a facility, whatever tenant it claims.
    await request(app.getHttpServer()).post('/api/istoria-klinis/create').set('Authorization', `Bearer ${userAToken}`).send({
      pasien_id: patientBId,
      facility_id: facilityBId,
      keluhan_subjektif: 'forged facility',
      kode_icd10: 'R50.9',
    }).expect(400);

    // And neither half is usable on its own for reading foreign records.
    await request(app.getHttpServer()).get(`/api/istoria-klinis/${visitBId}?facility_id=${facilityAId}&tenant_id=${tenantB}`)
      .set('Authorization', `Bearer ${userAToken}`)
      .expect(404);
    await request(app.getHttpServer()).get(`/api/istoria-klinis/pasien/${patientBId}?tenant_id=${tenantA}`)
      .set('Authorization', `Bearer ${userAToken}`)
      .expect(404);
  });
});
