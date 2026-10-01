import { Test, TestingModule } from '@nestjs/testing';
import { PasienController } from './pasien.controller';

describe('PasienController', () => {
  let controller: PasienController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PasienController],
    }).compile();

    controller = module.get<PasienController>(PasienController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
