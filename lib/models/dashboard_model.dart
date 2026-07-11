
class DashboardStats {
  final Map<String, dynamic> admin;
  final int total, passed, failed;
  final List<FaultData> faultBreakdown;

  DashboardStats({
    required this.admin,
    required this.total,
    required this.passed,
    required this.failed,
    required this.faultBreakdown,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      admin: json['admin'] ?? {},
      total: json['total'] ?? 0,
      passed: json['passed'] ?? 0,
      failed: json['failed'] ?? 0,
      faultBreakdown: (json['faultBreakdown'] as List? ?? [])
          .map((i) => FaultData.fromJson(i))
          .toList(),
    );
  }
}

class FaultData {
  final String faultClass;
  final int count;
  FaultData({required this.faultClass, required this.count});
  factory FaultData.fromJson(Map<String, dynamic> json) =>
      FaultData(faultClass: json['fault_class'], count: json['count']);
}