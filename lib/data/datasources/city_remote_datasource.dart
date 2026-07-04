import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/data/models/city_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for city operations
abstract class CityRemoteDataSource {
  /// Get all cities
  Future<List<CityModel>> getCities();

  /// Get a single city by ID or slug
  Future<CityModel> getCity(String identifier);
}

/// Implementation of CityRemoteDataSource using Supabase.
class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CityRemoteDataSourceImpl({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Future<List<CityModel>> getCities() async {
    try {
      final data = await _supabaseClient
          .from('cities')
          .select('id, name, slug, photo_url, courts:courts(count)')
          .order('name');

      return data.map((json) => CityModel.fromJson(_cityJson(json))).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to load cities: $e');
    }
  }

  @override
  Future<CityModel> getCity(String identifier) async {
    try {
      final query = _supabaseClient
          .from('cities')
          .select('id, name, slug, photo_url, courts:courts(count)');

      final data = int.tryParse(identifier) != null
          ? await query.eq('id', int.parse(identifier)).single()
          : await query.eq('slug', identifier).single();

      return CityModel.fromJson(_cityJson(data));
    } catch (e) {
      throw ServerException(message: 'Failed to load city: $e');
    }
  }

  Map<String, dynamic> _cityJson(Map<String, dynamic> json) {
    final courts = json['courts'];
    final courtsCount = courts is List && courts.isNotEmpty
        ? (courts.first['count'] as num?)?.toInt() ?? 0
        : 0;

    return {
      'id': (json['id'] as num).toInt(),
      'name': json['name'],
      'slug': json['slug'],
      'photo_url': json['photo_url'],
      'courts_count': courtsCount,
    };
  }
}
