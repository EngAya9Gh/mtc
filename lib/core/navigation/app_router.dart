import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/home/presentation/views/main_screen.dart';

import '../../features/auth/presentation/views/terms_screen.dart';
import '../../features/medical_tasks/presentation/views/task_type_screen.dart';
import '../../features/medical_tasks/presentation/views/task_list_screen.dart';
import '../../features/medical_tasks/presentation/views/task_map_screen.dart';
import '../../features/medical_tasks/presentation/views/sample_collection_screen.dart';
import '../../features/medical_tasks/presentation/views/signature_submit_screen.dart';
import '../../features/medical_tasks/presentation/views/bag_scan_screen.dart';
import '../../features/medical_tasks/presentation/views/first_sample_info_screen.dart';
import '../../features/profile/presentation/views/profile_screen.dart';
import '../../features/schedule/presentation/views/schedule_screen.dart';
import '../../features/notifications/presentation/views/notifications_screen.dart';
import '../../features/settings/presentation/views/privacy_policy_screen.dart';
import '../../features/settings/presentation/views/scanner_settings_screen.dart';
import '../../features/home/presentation/views/car_inspection_screen.dart';
import '../../features/medical_tasks/data/models/task_model.dart';
import '../../features/samples_pull_out/data/models/client_task_model.dart';
import '../../features/freezer/presentation/views/freezer_out_bags_screen.dart';
import '../../features/freezer/presentation/views/task_status_screen.dart';
import '../../features/samples_pull_out/presentation/views/pull_out_tasks_screen.dart';
import '../../features/samples_pull_out/presentation/views/pull_out_scan_container_screen.dart';
import '../../features/samples_pull_out/presentation/views/pull_out_remove_bags_screen.dart';
import '../../features/samples_pull_out/presentation/bloc/pull_out_cubit.dart';
import '../../data/providers/user_info_provider.dart';

class AppRouter {
  static const String login = '/login';
  static const String terms = '/terms';
  static const String main = '/main';
  static const String taskType = '/task_type';
  static const String taskList = '/task_list/:status';
  static const String taskMap = '/task_map';
  static const String sampleCollection = '/sample_collection';
  static const String freezerOutBags = '/freezer_out_bags';
  static const String taskStatus = '/task_status';
  static const String pullOutTasks = '/pull_out_tasks';
  static const String pullOutScanContainer = '/pull_out_scan_container';
  static const String pullOutRemoveBags = '/pull_out_remove_bags';

  static final router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      final isLoggedIn = UserInfo().isLoggedIn;
      final isLoggingIn = state.uri.path == login;

      if (!isLoggedIn && !isLoggingIn) {
        return login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: main,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: taskType,
        builder: (context, state) => const TaskTypeScreen(),
      ),
      GoRoute(
        path: taskList,
        builder: (context, state) {
          final status = state.pathParameters['status']!;
          return TaskListScreen(status: status);
        },
      ),
      GoRoute(
        path: taskMap,
        builder: (context, state) {
          final task = state.extra as MedicalTask;
          return TaskMapScreen(task: task);
        },
      ),
      GoRoute(
        path: '/first_sample_info',
        builder: (context, state) {
          final task = state.extra as MedicalTask;
          return FirstSampleInfoScreen(task: task);
        },
      ),
      GoRoute(
        path: sampleCollection,
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            return SampleCollectionScreen(
              task: extra['task'] as MedicalTask,
              initialTemp: extra['initialTemp'] as String?,
              initialType: extra['initialType'] as String?,
            );
          }
          final task = state.extra as MedicalTask;
          return SampleCollectionScreen(task: task);
        },
      ),
      GoRoute(
        path: '/signature',
        builder: (context, state) {
          final task = state.extra as MedicalTask;
          return SignatureSubmitScreen(task: task);
        },
      ),
      GoRoute(
        path: '/bag_scan',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BagScanScreen(
            temp: extra?['temp'] as String?,
            type: extra?['type'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/car_inspection',
        builder: (context, state) => const CarInspectionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy_policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/scanner_settings',
        builder: (context, state) => const ScannerSettingsScreen(),
      ),
      GoRoute(
        path: freezerOutBags,
        builder: (context, state) {
          final task = state.extra as MedicalTask;
          return FreezerOutBagsScreen(task: task);
        },
      ),
      GoRoute(
        path: taskStatus,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TaskStatusScreen(
            isSuccess: extra['isSuccess'] as bool,
            message: extra['message'] as String,
            taskId: extra['taskId'] as int?,
          );
        },
      ),
      GoRoute(
        path: pullOutTasks,
        builder: (context, state) => const PullOutTasksScreen(),
      ),
      GoRoute(
        path: pullOutScanContainer,
        builder: (context, state) {
          final destination = state.extra as ClientTaskModel;
          return PullOutScanContainerScreen(destination: destination);
        },
      ),
      GoRoute(
        path: pullOutRemoveBags,
        builder: (context, state) {
          final cubit = state.extra as PullOutCubit;
          return PullOutRemoveBagsScreen(cubit: cubit);
        },
      ),
    ],
  );
}
