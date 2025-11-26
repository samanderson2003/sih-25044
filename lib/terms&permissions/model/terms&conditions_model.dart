class TermsConditionsModel {
  final bool isAccepted;
  final DateTime? acceptedAt;
  final String userId;

  TermsConditionsModel({
    required this.isAccepted,
    this.acceptedAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'isAccepted': isAccepted,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  factory TermsConditionsModel.fromJson(Map<String, dynamic> json) {
    return TermsConditionsModel(
      isAccepted: json['isAccepted'] ?? false,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      userId: json['userId'] ?? '',
    );
  }
}

class PermissionsModel {
  final bool locationGranted;
  final bool cameraGranted;
  final bool galleryGranted;
  final DateTime? grantedAt;

  PermissionsModel({
    required this.locationGranted,
    required this.cameraGranted,
    required this.galleryGranted,
    this.grantedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationGranted': locationGranted,
      'cameraGranted': cameraGranted,
      'galleryGranted': galleryGranted,
      'grantedAt': grantedAt?.toIso8601String(),
    };
  }

  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    return PermissionsModel(
      locationGranted: json['locationGranted'] ?? false,
      cameraGranted: json['cameraGranted'] ?? false,
      galleryGranted: json['galleryGranted'] ?? false,
      grantedAt: json['grantedAt'] != null
          ? DateTime.parse(json['grantedAt'])
          : null,
    );
  }

  bool get allGranted => locationGranted && cameraGranted && galleryGranted;
}
