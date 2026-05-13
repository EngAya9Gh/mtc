import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/theme/app_theme.dart';
import 'core/services/di/di_container.dart';
import 'core/services/locale/locale_cubit.dart';
import 'core/utils/app_strings.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBBLnF3uALzo5NPzTm1eRcfD2uPpjpU6nE",
          authDomain: "mtcapp-df2d2.firebaseapp.com",
          projectId: "mtcapp-df2d2",
          storageBucket: "mtcapp-df2d2.firebasestorage.app",
          messagingSenderId: "1094753995290",
          appId: "1:1094753995290:web:10c32e90d5d0899cbe1fa3",
          measurementId: "G-BGX795E2R5",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await initDi();
  runApp(const BlazmaLogisticsApp());
}

class BlazmaLogisticsApp extends StatelessWidget {
  const BlazmaLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            locale: locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}
