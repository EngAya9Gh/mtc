import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/home/presentation/views/main_screen.dart';

import '../../features/auth/presentation/views/terms_screen.dart';
import '../../features/medical_tasks/presentation/views/task_type_screen.dart';
import '../../features/medical_tasks/presentation/views/task_list_screen.dart';

import '../../data/providers/user_info_provider.dart';

class AppRouter {
  static const String login = '/login';
  static const String terms = '/terms';
  static const String main = '/main';
  static const String taskType = '/task_type';
  static const String taskList = '/task_list/:status';

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
    ],
  );
}
