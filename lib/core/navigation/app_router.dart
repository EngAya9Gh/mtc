import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/home/presentation/views/main_screen.dart';

import '../../features/auth/presentation/views/terms_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String terms = '/terms';
  static const String main = '/main';

  static final router = GoRouter(
    initialLocation: login,
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
    ],
  );
}
