export type JenisKelamin = 'Laki-laki' | 'Perempuan';

export class PasienEntity {
	user_id: string;
	no_ktp: string | null;
	medical_record_number: string;
	facility_id?: string;
	nama_lengkap: string;
	tanggal_lahir: Date;
	tempat_lahir: string;
	jenis_kelamin: JenisKelamin;
	municipality?: string;
	administrative_post?: string;
	village?: string;
	fingerprint_hash?: string;
	tanggal_terdaftar: Date;
	updated_at: Date;
}