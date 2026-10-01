export type StatusSinkronisasi = 'Pending' | 'Synced' | 'Failed';

export class IstoriaKlinisEntity {
	kunjungan_id: string;
	pasien_id: string;
	tenant_id: string;
	tanggal_kunjungan: Date;
	keluhan_subjektif: string;
	pemeriksaan_objektif: string;
	analisis_asesmen: string;
	rencana_tindakan: string;
	kode_icd10: string;
	nama_penyakit_lokal: string;
	status_sinkronisasi: StatusSinkronisasi;
}