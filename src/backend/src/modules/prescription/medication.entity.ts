export interface MedicationEntity {
  medication_id: string;
  name: string;
  generic_name?: string;
  form?: string;
  strength?: string;
  unit?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}