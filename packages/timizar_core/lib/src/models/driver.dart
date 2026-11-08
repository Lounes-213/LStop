import 'vehicle.dart';

enum DriverApprovalStatus {
  pending,
  approved,
  rejected;

  static DriverApprovalStatus fromString(String status) {
    return switch (status.toLowerCase()) {
      'approved' => DriverApprovalStatus.approved,
      'rejected' => DriverApprovalStatus.rejected,
      _ => DriverApprovalStatus.pending,
    };
  }
}

class Driver {
  final String id;
  final String? licenseNumber;
  final DriverApprovalStatus approvalStatus;
  final bool isOnline;
  final double ratingAvg;
  final int ratingCount;
  final Vehicle? vehicle;

  const Driver({
    required this.id,
    this.licenseNumber,
    required this.approvalStatus,
    required this.isOnline,
    required this.ratingAvg,
    required this.ratingCount,
    this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    Vehicle? v;
    if (json['vehicle'] != null) {
      v = Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>);
    } else if (json['vehicle_id'] != null || json['vehicle_make'] != null) {
      v = Vehicle.fromJson(json);
    }

    return Driver(
      id: json['id'] as String,
      licenseNumber: json['license_number'] as String?,
      approvalStatus: DriverApprovalStatus.fromString(json['approval_status'] as String? ?? 'pending'),
      isOnline: (json['is_online'] as int? ?? 0) == 1 || (json['isOnline'] as bool? ?? false),
      ratingAvg: (json['rating_avg'] as num? ?? 5.0).toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      vehicle: v,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'licenseNumber': licenseNumber,
    'approvalStatus': approvalStatus.name,
    'isOnline': isOnline,
    'ratingAvg': ratingAvg,
    'ratingCount': ratingCount,
    'vehicle': vehicle?.toJson(),
  };
}

