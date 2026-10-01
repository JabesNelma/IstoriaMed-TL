import { Test, TestingModule } from '@nestjs/testing';
import { PasienService } from '../pasien/pasien.service';
import { IstoriaKlinisService } from './istoria_klinis.service';

describe('IstoriaKlinisService', () => {
  let service: IstoriaKlinisService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [IstoriaKlinisService, PasienService],
    }).compile();

    service = module.get<IstoriaKlinisService>(IstoriaKlinisService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
