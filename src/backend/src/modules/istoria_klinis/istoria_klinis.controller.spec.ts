import { Test, TestingModule } from '@nestjs/testing';
import { IstoriaKlinisController } from './istoria_klinis.controller';

describe('IstoriaKlinisController', () => {
  let controller: IstoriaKlinisController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [IstoriaKlinisController],
    }).compile();

    controller = module.get<IstoriaKlinisController>(IstoriaKlinisController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
