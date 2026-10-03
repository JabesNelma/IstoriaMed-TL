import { Column, Entity, Index, PrimaryColumn } from 'typeorm';

@Entity({ name: 'patients' })
@Index('uq_patients_no_ktp', ['no_ktp'], { unique: true })
export class PatientRecord {
  @PrimaryColumn({ type: 'char', length: 36, name: 'patient_id' })
  patient_id!: string;

  @Column({ type: 'varchar', length: 64, unique: true })
  medical_record_number!: string;

  @Column({ type: 'char', length: 36, nullable: true })
  facility_id!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  no_ktp!: string | null;

  @Column({ type: 'varchar', length: 100 })
  nama_lengkap!: string;

  @Column({ type: 'date' })
  tanggal_lahir!: string;

  @Column({ type: 'varchar', length: 100 })
  tempat_lahir!: string;

  @Column({ type: 'varchar', length: 20 })
  jenis_kelamin!: 'Laki-laki' | 'Perempuan';

  @Column({ type: 'varchar', length: 100, nullable: true })
  municipality!: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  administrative_post!: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  village!: string | null;

  @Column({ type: 'text', nullable: true })
  fingerprint_hash!: string | null;

  @Column({ type: 'datetime', name: 'created_at' })
  tanggal_terdaftar!: Date;

  @Column({ type: 'datetime' })
  updated_at!: Date;
}
