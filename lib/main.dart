import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/config/app_config.dart';
import 'package:padalpro/core/constants/app_constants.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/navigation/route_observer.dart';
import 'package:padalpro/core/theme/app_theme.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/blocs/booking/booking.dart';
import 'package:padalpro/presentation/blocs/city/city.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/splash/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.hasSupabaseConfig) {
    runApp(const MissingSupabaseConfigApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  await initializeDependencies();
  runApp(const PadalProApp());
}

class MissingSupabaseConfigApp extends StatelessWidget {
  const MissingSupabaseConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase config is missing. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class PadalProApp extends StatelessWidget {
  const PadalProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => sl<CityBloc>()..add(const CitiesFetchRequested()),
        ),
        BlocProvider(
          create: (_) => sl<CourtBloc>()..add(const FeaturedCourtsFetchRequested()),
        ),
        BlocProvider(
          create: (_) => sl<BookingBloc>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorObservers: [routeObserver],
        home: const SplashPage(),
      ),
    );
  }
}
