export type JenisKelamin = 'Laki-laki' | 'Perempuan';

export class PasienEntity {
	user_id: string;
	no_ktp: string;
	nama_lengkap: string;
	tanggal_lahir: Date;
	tempat_lahir: string;
	jenis_kelamin: JenisKelamin;
	fingerprint_hash?: string;
	tanggal_terdaftar: Date;
}