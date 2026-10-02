import { Test, TestingModule } from '@nestjs/testing';
import { PasienService } from '../pasien/pasien.service';
import { IstoriaKlinisController } from './istoria_klinis.controller';
import { IstoriaKlinisService } from './istoria_klinis.service';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../auth/roles.guard';

describe('IstoriaKlinisController', () => {
  let controller: IstoriaKlinisController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [IstoriaKlinisController],
      providers: [{ provide: IstoriaKlinisService, useValue: {} }, { provide: PasienService, useValue: {} }],
    }).overrideGuard(AuthGuard).useValue({ canActivate: () => true }).overrideGuard(RolesGuard).useValue({ canActivate: () => true }).compile();

    controller = module.get<IstoriaKlinisController>(IstoriaKlinisController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
