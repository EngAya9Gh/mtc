import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/end_points.dart';
import '../network/api_client.dart';
import '../../../features/auth/data/data_sources/auth_remote_data_source.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> initDi() async {
  // Core
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPrefs);

  final dio = Dio(
    BaseOptions(
      baseUrl: EndPoints.baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  getIt.registerLazySingleton(() => dio);
  
  getIt.registerLazySingleton(() => ApiClient(getIt(), getIt()));

  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()));

  // Blocs
  // getIt.registerFactory(() => AuthBloc(getIt()));
}
