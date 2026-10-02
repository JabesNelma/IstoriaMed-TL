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

  async function createApp() {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await instance.init();
    return instance;
  }

  async function addFacilityMembership(userId: string, code: string, tenant: string, role: string) {
    const facilityId = randomUUID();
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
    await database.query('DELETE FROM clinical_visits');
    await database.query('DELETE FROM patients');
    await database.query('DELETE FROM staff_profiles');
    await database.query('DELETE FROM facility_memberships');
    await database.query('DELETE FROM facilities');
    await database.query('DELETE FROM users');

    const userA = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'a@example.com', password: 'password-a-123' }).expect(201);
    const userB = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'b@example.com', password: 'password-b-123' }).expect(201);
    const pharmacy = await request(app.getHttpServer()).post('/api/auth/register').send({ login_identifier: 'pharmacy@example.com', password: 'password-p-123' }).expect(201);
    tenantA = `tenant-${randomUUID()}`;
    tenantB = `tenant-${randomUUID()}`;
    const facilityAId = await addFacilityMembership(userA.body.user.user_id, `A-${randomUUID()}`, tenantA, 'DOCTOR');
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
});
