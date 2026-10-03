import * as dotenv from 'dotenv';
import * as path from 'path';
import * as fs from 'fs';

// Memaksa dotenv membaca file .env di root backend secara instan
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

import type { DataSourceOptions } from 'typeorm';

import { ClinicalVisitRecord } from './entities/clinical-visit.record';
import { PatientRecord } from './entities/patient.record';
import { UserRecord } from './entities/user.record';
import { FacilityRecord } from './entities/facility.record';
import { FacilityMembershipRecord } from './entities/facility-membership.record';
import { StaffRecord } from './entities/staff.record';
import { TenantRecord } from './entities/tenant.record';
import { SyncOperationRecord } from './entities/sync-operation.record';
import { MedicationRecord } from './entities/medication.record';
import { PrescriptionRecord } from './entities/prescription.record';
import { PrescriptionItemRecord } from './entities/prescription-item.record';

export function getDatabaseOptions(): DataSourceOptions {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error('DATABASE_URL is required to start the backend.');
  }

  // Jalur bundle sertifikat CA standar untuk OS Fedora Anda
  const fedoraCertPath = '/etc/pki/tls/certs/ca-bundle.crt';
  let sslConfig: any = false;

  if (process.env.DATABASE_SSL === 'true') {
    if (fs.existsSync(fedoraCertPath)) {
      sslConfig = {
        ca: fs.readFileSync(fedoraCertPath),
        rejectUnauthorized: true,
      };
    } else {
      // Fallback jika sertifikat lokal tidak ditemukan, tetap paksa SSL untuk TiDB
      sslConfig = {
        rejectUnauthorized: true,
      };
    }
  }

  return {
    type: 'mysql',
    url,
    // TiDB Cloud reaps idle pooled sockets well before the server side
    // wait_timeout (28800s). Without TCP keepalive a request that grabs an
    // already reaped socket waits forever for a reply that never arrives, and
    // without idleTimeout the pool keeps handing out those dead sockets.
    extra: {
      connectionLimit: 10,
      // Probe idle sockets so a reaped peer is noticed instead of hanging.
      enableKeepAlive: true,
      keepAliveInitialDelay: 10_000,
      // Retire sockets before the serverless tier drops them (observed
      // between 30s and 60s of inactivity).
      idleTimeout: 30_000,
      maxIdle: 10,
      idleLimit: 5,
      // Bound the cold reconnect, which the serverless tier rate limits.
      connectTimeout: 30_000,
    },
    entities: [
      PatientRecord, 
      ClinicalVisitRecord, 
      UserRecord, 
      FacilityRecord, 
      FacilityMembershipRecord, 
      StaffRecord, 
      TenantRecord, 
      SyncOperationRecord, 
      MedicationRecord, 
      PrescriptionRecord, 
      PrescriptionItemRecord
    ],
    migrations: [path.join(__dirname, 'migrations/*.js')],
    synchronize: false,
    migrationsRun: false,
    ssl: sslConfig,
  };
}
