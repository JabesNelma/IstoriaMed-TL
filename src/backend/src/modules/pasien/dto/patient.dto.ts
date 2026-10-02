import { Transform } from 'class-transformer';
import { IsDateString, IsIn, IsOptional, IsString, Length, Matches } from 'class-validator';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class CreatePatientDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  no_ktp?: string | null;

  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'nama_lengkap must not be blank' })
  nama_lengkap!: string;

  @IsDateString()
  tanggal_lahir!: string;

  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'tempat_lahir must not be blank' })
  tempat_lahir!: string;

  @IsIn(['Laki-laki', 'Perempuan'])
  jenis_kelamin!: 'Laki-laki' | 'Perempuan';

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  municipality?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  administrative_post?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  village?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  fingerprint_hash?: string;
}

export class UpdatePatientDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 50)
  no_ktp?: string | null;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'nama_lengkap must not be blank' })
  nama_lengkap?: string;

  @IsOptional()
  @IsDateString()
  tanggal_lahir?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'tempat_lahir must not be blank' })
  tempat_lahir?: string;

  @IsOptional()
  @IsIn(['Laki-laki', 'Perempuan'])
  jenis_kelamin?: 'Laki-laki' | 'Perempuan';

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  municipality?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  administrative_post?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  village?: string;
}

export class SearchPatientDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 100)
  q?: string;
}
