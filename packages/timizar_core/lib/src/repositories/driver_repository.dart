import '../models/driver.dart';
import '../utils/result.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

abstract interface class DriverRepository {
  Future<Result<Driver, String>> getDriverStatus();
  Future<Result<bool, String>> toggleShift(bool isOnline);
  Future<Result<void, String>> submitOnboarding({
    required String licenseNumber,
    required String licenseDocumentUrl,
    required String idCardDocumentUrl,
    required String insuranceDocumentUrl,
    required Map<String, dynamic> vehicle,
  });
  Future<Result<Map<String, dynamic>, String>> getEarnings();
}

class DriverRepositoryImpl implements DriverRepository {
  final ApiClient _apiClient;

  DriverRepositoryImpl([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<Driver, String>> getDriverStatus() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverStatus,
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) => Success(Driver.fromJson(data['driver'] as Map<String, dynamic>)),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<bool, String>> toggleShift(bool isOnline) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverShift,
      data: {'isOnline': isOnline},
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) => Success(data['isOnline'] as bool? ?? isOnline),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<void, String>> submitOnboarding({
    required String licenseNumber,
    required String licenseDocumentUrl,
    required String idCardDocumentUrl,
    required String insuranceDocumentUrl,
    required Map<String, dynamic> vehicle,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.driverOnboard,
      data: {
        'licenseNumber': licenseNumber,
        'licenseDocumentUrl': licenseDocumentUrl,
        'idCardDocumentUrl': idCardDocumentUrl,
        'insuranceDocumentUrl': insuranceDocumentUrl,
        'vehicle': vehicle,
      },
    );

    return res.when(
      success: (_) => const Success(null),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, String>> getEarnings() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverEarnings,
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) => Success(data['earnings'] as Map<String, dynamic>? ?? {}),
      failure: (err) => Failure(err),
    );
  }
}

