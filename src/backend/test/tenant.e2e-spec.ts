import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import request from 'supertest';
import type { App } from 'supertest/types';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';

/**
 * Phase 9 - Tenant domain foundation.
 *
 * Tenant identity is now an authoritative row instead of a free text label.
 * These tests cover the administration API (central authority only), the
 * suspension semantics that flow through AuthService, and the referential
 * guarantees that come from the new foreign keys.
 */
describe('Tenant domain (e2e)', () => {
  let app: INestApplication<App>;
  let database: DataSource;
  let adminToken: string;
  let adminUserId: string;
  let centralTenantId: string;

  async function createApp() {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await instance.init();
    return instance;
  }

  /** Registers a user through the public API and returns its id. */
  async function registerUser(loginIdentifier: string, password: string): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ login_identifier: loginIdentifier, password })
      .expect(201);
    return response.body.user.user_id as string;
  }

  async function login(loginIdentifier: string, password: string): Promise<{ token: string; memberships: Array<{ facility_id: string; tenant_id: string; role: string }> }> {
    const response = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ login_identifier: loginIdentifier, password })
      .expect(201);
    return {
      token: response.body.access_token as string,
      memberships: response.body.user.memberships as Array<{ facility_id: string; tenant_id: string; role: string }>,
    };
  }

  /** Inserts the tenant, its facility and the membership in one step. */
  async function addFacilityMembership(userId: string, tenant: string, role: string): Promise<string> {
    const facilityId = randomUUID();
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenant],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $2, 'CHC', $3, NOW(), NOW())`,
      [facilityId, `F-${randomUUID()}`, tenant],
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
    // Children before parents; Phase 9 adds tenants as the new root.
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

    // The central authority: an admin whose own tenant stays active, which is
    // what lets it suspend and recover any other tenant.
    adminUserId = await registerUser('tenant-admin@example.com', 'admin-password-123');
    centralTenantId = `pusat-${randomUUID()}`;
    await addFacilityMembership(adminUserId, centralTenantId, 'SUPER_ADMIN');
    adminToken = (await login('tenant-admin@example.com', 'admin-password-123')).token;
  });

  afterEach(async () => {
    await app.close();
  });

  it('refuses tenant administration to anonymous and non administrative callers', async () => {
    await request(app.getHttpServer()).post('/api/admin/tenants').send({ tenant_id: 'chc-dili', name: 'CHC Dili' }).expect(401);

    const doctorId = await registerUser('tenant-doctor@example.com', 'doctor-password-123');
    await addFacilityMembership(doctorId, `klinik-${randomUUID()}`, 'DOCTOR');
    const doctor = await login('tenant-doctor@example.com', 'doctor-password-123');
    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${doctor.token}`)
      .send({ tenant_id: 'chc-dili', name: 'CHC Dili' })
      .expect(403);
  });

  it('creates a tenant and normalizes the identifier to a lowercase slug', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: '  CHC-Dili ', name: '  CHC Dili  ' })
      .expect(201);

    expect(response.body.tenant_id).toBe('chc-dili');
    expect(response.body.name).toBe('CHC Dili');
    expect(response.body.is_active).toBe(true);
  });

  it('rejects a duplicate tenant identifier with a conflict', async () => {
    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: 'chc-dili', name: 'CHC Dili' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: 'CHC-DILI', name: 'Another Dili' })
      .expect(409);
  });

  it('rejects a tenant identifier that is not a lowercase slug', async () => {
    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: 'Bad Tenant!', name: 'Malformed' })
      .expect(400);
    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: '-leading-dash', name: 'Malformed' })
      .expect(400);
  });

  it('renames a tenant and reports unknown identifiers as not found', async () => {
    await request(app.getHttpServer())
      .post('/api/admin/tenants')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ tenant_id: 'chc-dili', name: 'CHC Dili' })
      .expect(201);

    const renamed = await request(app.getHttpServer())
      .patch('/api/admin/tenants/chc-dili')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ name: 'CHC Dili Sentral' })
      .expect(200);
    expect(renamed.body.name).toBe('CHC Dili Sentral');

    const detail = await request(app.getHttpServer())
      .get('/api/admin/tenants/chc-dili')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(detail.body.name).toBe('CHC Dili Sentral');

    await request(app.getHttpServer()).get('/api/admin/tenants/no-such-tenant').set('Authorization', `Bearer ${adminToken}`).expect(404);
  });

  it('lists active tenants by default and includes suspended ones only when asked', async () => {
    await request(app.getHttpServer()).post('/api/admin/tenants').set('Authorization', `Bearer ${adminToken}`).send({ tenant_id: 'tenant-aaa', name: 'Tenant A' }).expect(201);
    await request(app.getHttpServer()).post('/api/admin/tenants').set('Authorization', `Bearer ${adminToken}`).send({ tenant_id: 'tenant-bbb', name: 'Tenant B' }).expect(201);
    await request(app.getHttpServer()).patch('/api/admin/tenants/tenant-bbb').set('Authorization', `Bearer ${adminToken}`).send({ is_active: false }).expect(200);

    // The admin's own tenant is active as well, so a tenant listing has to
    // include it: findAll() returns every active tenant ordered by tenant_id.
    // `.sort()` keeps the expectation independent of the id prefix.
    const activeOnly = await request(app.getHttpServer()).get('/api/admin/tenants').set('Authorization', `Bearer ${adminToken}`).expect(200);
    expect((activeOnly.body as Array<{ tenant_id: string }>).map((tenant) => tenant.tenant_id)).toEqual([centralTenantId, 'tenant-aaa'].sort());

    const withInactive = await request(app.getHttpServer()).get('/api/admin/tenants?include_inactive=true').set('Authorization', `Bearer ${adminToken}`).expect(200);
    expect((withInactive.body as Array<{ tenant_id: string }>).map((tenant) => tenant.tenant_id)).toEqual([centralTenantId, 'tenant-aaa', 'tenant-bbb'].sort());
  });

  it('suspends every membership of a tenant until it is reactivated', async () => {
    const doctorId = await registerUser('suspend-doctor@example.com', 'doctor-password-123');
    const suspendedTenantId = `susp-${randomUUID()}`;
    await addFacilityMembership(doctorId, suspendedTenantId, 'DOCTOR');
    const before = await login('suspend-doctor@example.com', 'doctor-password-123');
    expect(before.memberships.some((membership) => membership.tenant_id === suspendedTenantId)).toBe(true);

    // The doctor writes a patient while the tenant is active.
    const patient = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${before.token}`)
      .send({ no_ktp: null, nama_lengkap: 'Pasiente Suspended', tanggal_lahir: '1990-01-01', tempat_lahir: 'Dili', jenis_kelamin: 'Laki-laki' })
      .expect(201);
    const patientId = patient.body.data[0].user_id as string;

    await request(app.getHttpServer())
      .patch(`/api/admin/tenants/${suspendedTenantId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ is_active: false })
      .expect(200);

    // Login no longer reports the suspended membership...
    const suspended = await login('suspend-doctor@example.com', 'doctor-password-123');
    expect(suspended.memberships.some((membership) => membership.tenant_id === suspendedTenantId)).toBe(false);

    // ...and the token issued before the suspension loses its scope on every
    // request, because verifyPayload re-derives memberships per call. That
    // leaves the doctor with no membership at all, so RolesGuard rejects the
    // call instead of quietly serving an empty list.
    await request(app.getHttpServer()).get('/api/pasien').set('Authorization', `Bearer ${before.token}`).expect(403);

    // Reactivation restores the same token's scope without a re-login.
    await request(app.getHttpServer())
      .patch(`/api/admin/tenants/${suspendedTenantId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ is_active: true })
      .expect(200);
    const restored = await request(app.getHttpServer()).get('/api/pasien').set('Authorization', `Bearer ${before.token}`).expect(200);
    expect((restored.body as Array<{ user_id: string }>).map((row) => row.user_id)).toContain(patientId);
  });

  it('keeps a tenant that still owns facilities from being erased', async () => {
    const tenantId = `held-${randomUUID()}`;
    await addFacilityMembership(adminUserId, tenantId, 'SUPER_ADMIN');

    await expect(database.query('DELETE FROM tenants WHERE tenant_id = $1', [tenantId])).rejects.toThrow(
      /fk_facilities_tenant/,
    );
  });

  it('rejects a legacy visit that names a tenant which does not exist', async () => {
    // A real patient with no facility, so the only violated constraint is the
    // one this migration added: the visit's tenant reference.
    const patientId = randomUUID();
    await database.query(
      `INSERT INTO patients (patient_id, medical_record_number, nama_lengkap, tanggal_lahir, tempat_lahir,
                             jenis_kelamin, created_at, updated_at, facility_id)
       VALUES ($1, $2, 'Legacy Patient', '1990-01-01', 'Dili', 'Laki-laki', NOW(), NOW(), NULL)`,
      [patientId, `MRN-${randomUUID()}`],
    );
    await expect(
      database.query(
        `INSERT INTO clinical_visits (visit_id, pasien_id, facility_id, tenant_id, visit_date, keluhan_subjektif, kode_icd10, created_at, updated_at)
         VALUES ($1, $2, NULL, $3, NOW(), 'orphan tenant visit', 'R50.9', NOW(), NOW())`,
        [randomUUID(), patientId, `no-such-${randomUUID()}`],
      ),
    ).rejects.toThrow(/fk_clinical_visits_tenant/);
  });
});
