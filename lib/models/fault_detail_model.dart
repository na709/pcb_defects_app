class FaultDetailResponse {
  final int historyId;
  final String originalImage;
  final String resultImage;
  final List<FaultItem> faults;

  FaultDetailResponse({
    required this.historyId,
    required this.originalImage,
    required this.resultImage,
    required this.faults,
  });

  factory FaultDetailResponse.fromJson(Map<String, dynamic> json) {
    return FaultDetailResponse(
      historyId: json['history_id'],
      originalImage: json['original_image'],
      resultImage: json['result_image'],
      faults: (json['faults'] as List)
          .map((item) => FaultItem.fromJson(item))
          .toList(),
    );
  }
}

class FaultItem {
  final String faultClass;
  final double confidence;
  final List<double> bbox;

  FaultItem({
    required this.faultClass,
    required this.confidence,
    required this.bbox,
  });

  factory FaultItem.fromJson(Map<String, dynamic> json) {
    return FaultItem(
      faultClass: json['fault_class'],
      confidence: (json['confidence'] as num).toDouble(),
      bbox: List<double>.from(json['bbox'].map((e) => (e as num).toDouble())),
    );
  }
}