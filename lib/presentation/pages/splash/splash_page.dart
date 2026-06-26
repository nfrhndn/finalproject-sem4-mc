import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/presentation/blocs/auth/auth.dart';
import 'package:padbro/presentation/pages/browse/browse_page.dart';
import 'package:padbro/presentation/pages/onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    // Minimum splash duration for branding
    _startMinimumDelay();
  }

  Future<void> _startMinimumDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      _navigateTo(const BrowsePage());
    } else if (authState is AuthUnauthenticated || authState is AuthError) {
      _navigateTo(const OnboardingPage());
    }
    // If still loading, wait for BlocListener to handle it
  }

  void _navigateTo(Widget page) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle auth state changes after minimum delay
        if (state is AuthAuthenticated) {
          _navigateTo(const BrowsePage());
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _navigateTo(const OnboardingPage());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/icon app.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // App Name
                      Text(
                        'PadBro',
                        style: AppTextStyles.heading1.copyWith(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find & Book Padel Courts',
                        style: AppTextStyles.body.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
