import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:padbro/core/network/api_client.dart';
import 'package:padbro/data/datasources/auth_local_datasource.dart';
import 'package:padbro/data/datasources/auth_remote_datasource.dart';
import 'package:padbro/data/datasources/booking_remote_datasource.dart';
import 'package:padbro/data/datasources/city_remote_datasource.dart';
import 'package:padbro/data/datasources/court_remote_datasource.dart';
import 'package:padbro/data/datasources/search_local_datasource.dart';
import 'package:padbro/data/repositories/auth_repository_impl.dart';
import 'package:padbro/data/repositories/booking_repository_impl.dart';
import 'package:padbro/data/repositories/city_repository_impl.dart';
import 'package:padbro/data/repositories/court_repository_impl.dart';
import 'package:padbro/domain/repositories/auth_repository.dart';
import 'package:padbro/domain/repositories/booking_repository.dart';
import 'package:padbro/domain/repositories/city_repository.dart';
import 'package:padbro/domain/repositories/court_repository.dart';
import 'package:padbro/presentation/blocs/auth/auth_bloc.dart';
import 'package:padbro/presentation/blocs/booking/booking_bloc.dart';
import 'package:padbro/presentation/blocs/city/city_bloc.dart';
import 'package:padbro/presentation/blocs/court/court_bloc.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ==================== External ====================
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  // ==================== Core ====================
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(secureStorage: sl<FlutterSecureStorage>()),
  );

  // ==================== Data Sources ====================
  // Auth Remote
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Auth Local
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl<FlutterSecureStorage>()),
  );

  // City Remote
  sl.registerLazySingleton<CityRemoteDataSource>(
    () => CityRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Court Remote
  sl.registerLazySingleton<CourtRemoteDataSource>(
    () => CourtRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Booking Remote
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Search Local
  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(),
  );

  // ==================== Repositories ====================
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<CityRepository>(
    () => CityRepositoryImpl(
      remoteDataSource: sl<CityRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<CourtRepository>(
    () => CourtRepositoryImpl(
      remoteDataSource: sl<CourtRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: sl<BookingRemoteDataSource>(),
    ),
  );

  // ==================== BLoCs ====================
  // Using factory so each widget gets a fresh instance if needed
  // Or use registerLazySingleton if you want a single instance app-wide
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  sl.registerFactory<CityBloc>(
    () => CityBloc(cityRepository: sl<CityRepository>()),
  );

  sl.registerFactory<CourtBloc>(
    () => CourtBloc(courtRepository: sl<CourtRepository>()),
  );

  sl.registerFactory<BookingBloc>(
    () => BookingBloc(bookingRepository: sl<BookingRepository>()),
  );
}
