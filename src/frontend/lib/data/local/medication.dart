/// Read-only medication catalog entry.
///
/// The catalog is a global server owned reference list: it is not tenant or
/// facility scoped, it is never created from the device, and it is never part of
/// the offline queue. Only [Medication.medicationId] travels inside a
/// prescription; the clinical text always comes from the server.
class Medication {
  const Medication({
    required this.medicationId,
    required this.name,
    this.genericName,
    this.form,
    this.strength,
    this.unit,
    this.isActive = true,
  });

  final String medicationId;
  final String name;
  final String? genericName;
  final String? form;
  final String? strength;
  final String? unit;
  final bool isActive;

  factory Medication.fromApiJson(Map<String, dynamic> json) {
    return Medication(
      medicationId: json['medication_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      genericName: json['generic_name'] as String?,
      form: json['form'] as String?,
      strength: json['strength'] as String?,
      unit: json['unit'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Human readable label used by pickers and prescription summaries.
  String get label {
    final parts = <String>[name];
    if (strength != null && strength!.isNotEmpty) parts.add(strength!);
    if (form != null && form!.isNotEmpty) parts.add(form!);
    return parts.join(' - ');
  }
}