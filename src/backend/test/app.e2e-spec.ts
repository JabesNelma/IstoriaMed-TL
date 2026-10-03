import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }));
    await app.init();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('rejects an invalid patient request', () => {
    return request(app.getHttpServer())
      .post('/api/pasien/register')
      .send({ nama_lengkap: 'Incomplete' })
      .expect(401);
  });

  it('requires authentication for patient registration', () => {
    return request(app.getHttpServer())
      .post('/api/pasien/register')
      .send({
        no_ktp: null,
        nama_lengkap: 'Unknown Patient',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Laki-laki',
      })
      .expect(401);
  });

  afterEach(async () => {
    // `?.` keeps a failed bootstrap from masking the real error with an
    // unrelated "cannot read properties of undefined" from this hook.
    await app?.close();
  });
});
