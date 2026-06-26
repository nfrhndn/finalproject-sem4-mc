import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/constants/app_constants.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/navigation/route_observer.dart';
import 'package:padalpro/core/theme/app_theme.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/blocs/booking/booking.dart';
import 'package:padalpro/presentation/blocs/city/city.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const PadalProApp());
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
