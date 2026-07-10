class FilterModel {
  final List<String> faultClasses;
  final int? status;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterModel({
    required this.faultClasses,
    this.status,
    this.startDate,
    this.endDate,
  });


  Map<String, dynamic> toJson() {
    return {
      'faults': faultClasses.isEmpty ? null : faultClasses.join(','),
      'is_passed': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate != null
          ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59).toIso8601String()
          : null,
    };
  }
}