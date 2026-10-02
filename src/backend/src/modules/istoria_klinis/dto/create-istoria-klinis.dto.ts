import { IsDateString, IsOptional, IsString, IsUUID, Length } from 'class-validator';

export class CreateIstoriaKlinisDto {
  @IsString()
  @IsUUID()
  @Length(1, 100)
  pasien_id!: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  tenant_id?: string;

  @IsOptional()
  @IsString()
  @IsUUID()
  @Length(1, 100)
  staf_id?: string;

  @IsOptional()
  @IsDateString()
  visit_date?: string;

  @IsString()
  @Length(1, 5000)
  keluhan_subjektif!: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  pemeriksaan_objektif?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  analisis_asesmen?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  rencana_tindakan?: string;

  @IsString()
  @Length(1, 10)
  kode_icd10!: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  nama_penyakit_lokal?: string;
}

export class UpdateIstoriaKlinisDto {
  @IsOptional()
  @IsDateString()
  visit_date?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  keluhan_subjektif?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  pemeriksaan_objektif?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  analisis_asesmen?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  rencana_tindakan?: string;

  @IsOptional()
  @IsString()
  @Length(1, 10)
  kode_icd10?: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  nama_penyakit_lokal?: string;
}
