import { Test, TestingModule } from '@nestjs/testing';
import { PasienController } from './pasien.controller';
import { PasienService } from './pasien.service';
import { AuthGuard } from '../auth/auth.guard';
import { RolesGuard } from '../auth/roles.guard';

describe('PasienController', () => {
  let controller: PasienController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PasienController],
      providers: [{ provide: PasienService, useValue: {} }],
    }).overrideGuard(AuthGuard).useValue({ canActivate: () => true }).overrideGuard(RolesGuard).useValue({ canActivate: () => true }).compile();

    controller = module.get<PasienController>(PasienController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
