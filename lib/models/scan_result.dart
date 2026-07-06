class ScanResult {
  final int id;
  final String originalImage;
  final String createdAt;
  final int faultCount;

  ScanResult({
    required this.id,
    required this.originalImage,
    required this.createdAt,
    required this.faultCount,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      originalImage: json['original_image'],
      createdAt: json['created_at'],
      faultCount: json['fault_count'] ?? 0,
    );
  }
}