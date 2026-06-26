import 'package:padalpro/core/network/api_client.dart';
import 'package:padalpro/core/network/api_endpoints.dart';
import 'package:padalpro/data/models/city_model.dart';

/// Remote data source for city operations
abstract class CityRemoteDataSource {
  /// Get all cities
  Future<List<CityModel>> getCities();

  /// Get a single city by ID or slug
  Future<CityModel> getCity(String identifier);
}

/// Implementation of CityRemoteDataSource using ApiClient
class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  final ApiClient _apiClient;

  CityRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<CityModel>> getCities() async {
    final response = await _apiClient.get(ApiEndpoints.cities);

    final responseData = response.data as Map<String, dynamic>;
    final citiesData = responseData['data'] as List<dynamic>;

    return citiesData
        .map((json) => CityModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CityModel> getCity(String identifier) async {
    final response = await _apiClient.get(ApiEndpoints.cityDetails(identifier));

    final responseData = response.data as Map<String, dynamic>;
    return CityModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }
}
