import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/news/data/repositories/news_repository.dart';
import 'features/news/presentation/cubit/news_cubit.dart';
import 'features/competitions/data/repositories/standings_repository.dart';
import 'features/competitions/presentation/cubit/standings_cubit.dart';
import 'features/match_details/data/repositories/matches_repository.dart';
import 'features/match_details/presentation/cubit/matches_cubit.dart';
import 'features/favorites/presentation/cubit/favorites_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDYenUtRiVMgm13Rbkzve1ZtcmLHebHTRo",
      authDomain: "rabitati-f4cc1.firebaseapp.com",
      projectId: "rabitati-f4cc1",
      storageBucket: "rabitati-f4cc1.firebasestorage.app",
      messagingSenderId: "291249976817",
      appId: "1:291249976817:web:c2612843c213d1782c8050",
      measurementId: "G-5KHKPDQ7Q3",
    ),
  );

  runApp(const RabitatiApp());
}

class RabitatiApp extends StatelessWidget {
  const RabitatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NewsCubit>(
          create: (context) => NewsCubit(NewsRepository()),
        ),
        BlocProvider<MatchesCubit>(
          create: (context) => MatchesCubit(MatchesRepository()),
        ),
        BlocProvider<StandingsCubit>(
          create: (context) => StandingsCubit(StandingsRepository()),
        ),
        BlocProvider<FavoritesCubit>(
          create: (context) => FavoritesCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'رابطتي | RABITATI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const SplashPage(),
      ),
    );
  }
}