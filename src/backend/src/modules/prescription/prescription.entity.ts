export interface PrescriptionItemEntity {
  prescription_item_id: string;
  prescription_id: string;
  medication_id: string;
  dose: string;
  frequency: string;
  route?: string;
  duration?: string;
  quantity: number;
  instructions?: string;
  created_at: Date;
  updated_at: Date;
}

export interface PrescriptionEntity {
  prescription_id: string;
  visit_id: string;
  prescribed_by_staff_id: string;
  facility_id: string;
  tenant_id: string;
  prescribed_at: Date;
  notes?: string;
  items: PrescriptionItemEntity[];
  created_at: Date;
  updated_at: Date;
}