import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/end_points.dart';
import '../notifications/notification_service.dart';
import '../network/api_client.dart';
import '../../../features/auth/data/data_sources/auth_remote_data_source.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/medical_tasks/data/data_sources/task_remote_data_source.dart';
import '../../../features/medical_tasks/data/repositories/task_repository_impl.dart';
import '../../../features/medical_tasks/domain/repositories/task_repository.dart';
import '../../../features/medical_tasks/presentation/bloc/medical_task_bloc.dart';
import '../../../features/medical_tasks/presentation/bloc/sample_collection_cubit.dart';
import '../../../features/medical_tasks/presentation/bloc/signature_submit_cubit.dart';
import '../../../features/medical_tasks/presentation/bloc/task_map_cubit.dart';
import '../../../features/home/presentation/bloc/car_inspection_cubit.dart';
import '../../../features/schedule/presentation/bloc/schedule_cubit.dart';
import '../../../features/notifications/presentation/bloc/notifications_cubit.dart';
import '../../../features/settings/presentation/bloc/scanner_settings_cubit.dart';
import '../locale/locale_cubit.dart';
import '../../../features/freezer/data/data_sources/freezer_remote_data_source.dart';
import '../../../features/freezer/data/repositories/freezer_repository_impl.dart';
import '../../../features/freezer/domain/repositories/freezer_repository.dart';
import '../../../features/freezer/presentation/bloc/freezer_placement_cubit.dart';
import '../../../features/samples_pull_out/data/data_sources/samples_pull_out_remote_data_source.dart';
import '../../../features/samples_pull_out/data/repositories/samples_pull_out_repository_impl.dart';
import '../../../features/samples_pull_out/domain/repositories/samples_pull_out_repository.dart';
import '../../../features/samples_pull_out/presentation/bloc/pull_out_cubit.dart';
final getIt = GetIt.instance;

Future<void> initDi() async {
  // Core
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPrefs);
  getIt.registerLazySingleton(() => NotificationService());

  final dio = Dio(
    BaseOptions(
      baseUrl: EndPoints.debugBaseUrl,
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
  getIt.registerLazySingleton<TaskRemoteDataSource>(
      () => TaskRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<FreezerRemoteDataSource>(
      () => FreezerRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<SamplesPullOutRemoteDataSource>(
      () => SamplesPullOutRemoteDataSourceImpl(getIt()));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()));
  getIt.registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(getIt()));
  getIt.registerLazySingleton<FreezerRepository>(
      () => FreezerRepositoryImpl(getIt()));
  getIt.registerLazySingleton<SamplesPullOutRepository>(
      () => SamplesPullOutRepositoryImpl(getIt()));

  // Blocs
  getIt.registerFactory(() => AuthBloc(getIt(), getIt(), getIt()));
  getIt.registerFactory(() => MedicalTaskBloc(getIt()));
  getIt.registerFactory(() => CarInspectionCubit(getIt()));
  getIt.registerFactory(() => SampleCollectionCubit(getIt()));
  getIt.registerFactory(() => SignatureSubmitCubit(getIt()));
  getIt.registerFactory(() => TaskMapCubit(getIt()));
  getIt.registerFactory(() => ScheduleCubit(getIt()));
  getIt.registerFactory(() => NotificationsCubit(getIt()));
  getIt.registerFactory(() => ScannerSettingsCubit(getIt()));
  getIt.registerFactory(() => FreezerPlacementCubit(getIt()));
  getIt.registerFactory(() => PullOutCubit(getIt()));
  getIt.registerLazySingleton(() => LocaleCubit(getIt()));
}
