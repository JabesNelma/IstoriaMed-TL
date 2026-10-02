import { ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import request from 'supertest';
import type { App } from 'supertest/types';

import { AppModule } from '../src/app.module';
import { randomUUID } from 'node:crypto';

describe('Database persistence (e2e)', () => {
  let app: import('@nestjs/common').INestApplication<App>;
  let accessToken: string;
  let tenantId: string;

  async function createApp() {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }));
    await instance.init();
    return instance;
  }

  beforeEach(async () => {
    app = await createApp();
    const database = app.get(DataSource);
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
    await database.query('DELETE FROM users');

    const user = await request(app.getHttpServer()).post('/api/auth/register').send({
      login_identifier: 'database@example.com',
      password: 'test-password-123',
    }).expect(201);
    const facilityId = randomUUID();
    tenantId = 'tenant-database';
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW(), NOW())`,
      [facilityId, 'DB-FACILITY', 'Database Facility', 'CHC', tenantId],
    );
    await database.query(
      `INSERT INTO facility_memberships (membership_id, user_id, facility_id, role, is_active, created_at)
       VALUES ($1, $2, $3, $4, true, NOW())`,
      [randomUUID(), user.body.user.user_id, facilityId, 'DOCTOR'],
    );
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', 'Approved', NOW())`,
      [randomUUID(), user.body.user.user_id, facilityId, `DB-${randomUUID()}`],
    );
    const login = await request(app.getHttpServer()).post('/api/auth/login').send({
      login_identifier: 'database@example.com',
      password: 'test-password-123',
    }).expect(201);
    accessToken = login.body.access_token;
  });

  afterEach(async () => {
    await app.close();
  });

  it('persists a patient across application restart', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        no_ktp: 'E2E-001',
        nama_lengkap: 'Patient Persistence',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Laki-laki',
      })
      .expect(201);
    const patientId = response.body.data[0].user_id as string;

    await app.close();
    app = await createApp();

    const patients = await request(app.getHttpServer())
      .get('/api/pasien')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(patients.body).toEqual(expect.arrayContaining([
      expect.objectContaining({ user_id: patientId, no_ktp: 'E2E-001' }),
    ]));
  });

  it('accepts null KTP and rejects a duplicate real KTP', async () => {
    await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        no_ktp: null,
        nama_lengkap: 'Unknown One',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Perempuan',
      })
      .expect(201);

    const patient = {
      no_ktp: 'E2E-002',
      nama_lengkap: 'Known One',
      tanggal_lahir: '1990-01-01',
      tempat_lahir: 'Dili',
      jenis_kelamin: 'Perempuan',
    };
    await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${accessToken}`).send(patient).expect(201);
    await request(app.getHttpServer()).post('/api/pasien/register').set('Authorization', `Bearer ${accessToken}`).send(patient).expect(409);
  });

  it('supports scoped detail, search, and authorized update without changing ownership', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        no_ktp: null,
        nama_lengkap: 'Searchable Patient',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Perempuan',
      })
      .expect(201);
    const patientId = created.body.data[0].user_id as string;

    await request(app.getHttpServer())
      .get(`/api/pasien/${patientId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    const search = await request(app.getHttpServer())
      .get('/api/pasien')
      .query({ q: 'Searchable' })
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(search.body).toHaveLength(1);

    const updated = await request(app.getHttpServer())
      .patch(`/api/pasien/${patientId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ nama_lengkap: 'Updated Patient', tenant_id: 'attacker-tenant' })
      .expect(400);
    expect(updated.body.message).toEqual(expect.any(Array));

    const successfulUpdate = await request(app.getHttpServer())
      .patch(`/api/pasien/${patientId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ nama_lengkap: 'Updated Patient' })
      .expect(200);
    expect(successfulUpdate.body.nama_lengkap).toBe('Updated Patient');
    expect(successfulUpdate.body.facility_id).toBeDefined();
  });

  it('persists clinical visits and rejects an unknown patient relationship', async () => {
    const patient = await request(app.getHttpServer())
      .post('/api/pasien/register')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        no_ktp: null,
        nama_lengkap: 'Visit Patient',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Laki-laki',
      })
      .expect(201);
    const patientId = patient.body.data[0].user_id as string;
    const visit = {
      pasien_id: patientId,
      tenant_id: tenantId,
      keluhan_subjektif: 'Febre',
      kode_icd10: 'R50.9',
    };

    const created = await request(app.getHttpServer())
      .post('/api/istoria-klinis/create')
      .set('Authorization', `Bearer ${accessToken}`)
      .send(visit)
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/istoria-klinis/create')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ ...visit, pasien_id: '00000000-0000-0000-0000-000000000000' })
      .expect(404);

    await app.close();
    app = await createApp();

    const history = await request(app.getHttpServer())
      .get(`/api/istoria-klinis/pasien/${patientId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(history.body).toEqual(expect.arrayContaining([
      expect.objectContaining({ kunjungan_id: created.body.kunjungan_id }),
    ]));
  });
});