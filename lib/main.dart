import 'dart:async';

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
import 'package:padalpro/presentation/blocs/community/community.dart';
import 'package:padalpro/presentation/blocs/court/court.dart';
import 'package:padalpro/presentation/pages/auth/reset_password_page.dart';
import 'package:padalpro/presentation/pages/splash/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PadalProBootstrapApp());
}

class PadalProBootstrapApp extends StatefulWidget {
  const PadalProBootstrapApp({super.key});

  @override
  State<PadalProBootstrapApp> createState() => _PadalProBootstrapAppState();
}

class _PadalProBootstrapAppState extends State<PadalProBootstrapApp> {
  Object? _error;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      setState(() {
        _error =
            'Supabase config is missing. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...';
      });
      return;
    }

    try {
      await supabase.Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 20));
      await initializeDependencies();
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const PadalProApp();
    }

    if (_error != null) {
      return BootstrapMessageApp(
        message:
            'PadalPro failed to start.\n\n$_error\n\nStop the server, run flutter clean, then run the app again.',
      );
    }

    return const BootstrapMessageApp(message: 'Starting PadalPro...');
  }
}

class BootstrapMessageApp extends StatelessWidget {
  final String message;

  const BootstrapMessageApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
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
          create: (_) =>
              sl<CourtBloc>()..add(const FeaturedCourtsFetchRequested()),
        ),
        BlocProvider(create: (_) => sl<BookingBloc>()),
        BlocProvider(create: (_) => sl<CommunityBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorObservers: [routeObserver],
        home: const AuthSessionSync(child: SplashPage()),
      ),
    );
  }
}

class AuthSessionSync extends StatefulWidget {
  final Widget child;

  const AuthSessionSync({super.key, required this.child});

  @override
  State<AuthSessionSync> createState() => _AuthSessionSyncState();
}

class _AuthSessionSyncState extends State<AuthSessionSync> {
  StreamSubscription<supabase.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final event = data.event;
          if (event == supabase.AuthChangeEvent.signedIn ||
              event == supabase.AuthChangeEvent.tokenRefreshed ||
              event == supabase.AuthChangeEvent.userUpdated ||
              event == supabase.AuthChangeEvent.passwordRecovery) {
            if (!mounted) return;
            context.read<AuthBloc>().add(const AuthCheckRequested());
          }
          if (event == supabase.AuthChangeEvent.passwordRecovery) {
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
              );
            });
          }
          if (event == supabase.AuthChangeEvent.signedOut) {
            if (!mounted) return;
            context.read<AuthBloc>().add(const AuthStateReset());
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
