import 'package:isar/isar.dart';

part 'prescription_schema.g.dart';

/// One medication line inside a prescription.
///
/// [prescriptionItemId] and [medicationName] are server owned: the device never
/// invents an item identifier and never authors clinical text. The medication
/// name is copied from the catalog for offline display only.
@embedded
class PrescriptionItem {
  String? prescriptionItemId;
  String? medicationName;
  String? medicationStrength;

  late String medicationId;
  late String dose;
  late String frequency;
  String? route;
  String? duration;
  late int quantity;
  String? instructions;

  Map<String, dynamic> toSyncPayload() => {
    'medication_id': medicationId,
    'dose': dose,
    'frequency': frequency,
    if (route != null && route!.isNotEmpty) 'route': route,
    if (duration != null && duration!.isNotEmpty) 'duration': duration,
    'quantity': quantity,
    if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
  };

  static PrescriptionItem fromApiJson(Map<String, dynamic> json) {
    return PrescriptionItem()
      ..prescriptionItemId = json['prescription_item_id'] as String?
      ..medicationId = json['medication_id'] as String? ?? ''
      ..medicationName = json['medication_name'] as String?
      ..medicationStrength = json['medication_strength'] as String?
      ..dose = json['dose'] as String? ?? ''
      ..frequency = json['frequency'] as String? ?? ''
      ..route = json['route'] as String?
      ..duration = json['duration'] as String?
      ..quantity = (json['quantity'] as num?)?.toInt() ?? 0
      ..instructions = json['instructions'] as String?;
  }
}

/// A medication prescription written for one clinical visit.
///
/// Like the clinical visit, the prescription is an offline-first record: the
/// local row and its queue entry are written in one Isar transaction and the
/// same queue synchronizes it later.
///
/// [prescribedByStaffId], [facilityId] and [tenantId] are server owned. They are
/// never taken from the device and are never sent in a sync payload.
@collection
@Name('Prescription_2026_10_10')
class Prescription {
  Id id = Isar.autoIncrement;

  /// Canonical UUID reserved before the device went offline.
  String? remoteId;

  /// Clinical visit this prescription belongs to.
  @Index()
  late String visitId;

  String? prescribedByStaffId;
  String? facilityId;
  String? tenantId;

  DateTime? prescribedAt;
  String? notes;

  late List<PrescriptionItem> items;

  /// `Pending`, `Synced` or `Failed`.
  late String syncStatus;

  /// Offline sync payload.
  ///
  /// `prescription_id` is sent so the server adopts the identifier this device
  /// already reserved. Ownership fields are intentionally omitted.
  Map<String, dynamic> toSyncPayload() => {
    'prescription_id': remoteId,
    'visit_id': visitId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'items': items.map((item) => item.toSyncPayload()).toList(),
  };

  Map<String, dynamic> toApiJson() => {
    'visit_id': visitId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'items': items.map((item) => item.toSyncPayload()).toList(),
  };

  static Prescription fromApiJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PrescriptionItem.fromApiJson)
        .toList();
    return Prescription()
      ..remoteId = json['prescription_id'] as String?
      ..visitId = json['visit_id'] as String? ?? ''
      ..prescribedByStaffId = json['prescribed_by_staff_id'] as String?
      ..facilityId = json['facility_id'] as String?
      ..tenantId = json['tenant_id'] as String?
      ..prescribedAt = json['prescribed_at'] == null
          ? null
          : DateTime.parse(json['prescribed_at'] as String)
      ..notes = json['notes'] as String?
      ..items = rawItems
      ..syncStatus = json['status_sinkronisasi'] as String? ?? 'Synced';
  }
}