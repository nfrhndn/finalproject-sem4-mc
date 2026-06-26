import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/core/utils/snackbar_helper.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/pages/auth/sign_up_page.dart';
import 'package:padalpro/presentation/pages/browse/browse_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _handleSignIn() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Only listen when state actually changes (not on initial build)
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to browse page on successful login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const BrowsePage()),
            (route) => false,
          );
        } else if (state is AuthError) {
          // Show error snackbar at top
          SnackBarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://images.unsplash.com/photo-1723980839948-95ccbffd3cb4?q=80&w=1600&auto=format&fit=crop',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.textPrimary,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                    ],
                  ),
                ),
              );
            },
          ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form card
                        Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/icon app.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PadalPro',
                                  style: AppTextStyles.heading1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Heading inside card
                            Text(
                              'Welcome Back',
                              style: AppTextStyles.heading1.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue booking courts',
                              style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                            ),
                            const SizedBox(height: 24),

                            // Email field
                            _buildFieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            _buildFieldLabel('Password'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  SnackBarHelper.showInfo(context, 'Forgot password feature coming soon!');
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.bodySemibold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign in button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textPrimary,
                                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: AppTextStyles.buttonLarge,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Social login buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    onTap: () {
                                      context.read<AuthBloc>().add(
                                            const AuthGoogleSignInRequested(),
                                          );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.apple_rounded,
                                    label: 'Apple',
                                    onTap: () {
                                      SnackBarHelper.showInfo(context, 'Apple sign in coming soon!');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: AppTextStyles.body,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: AppTextStyles.buttonSmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodySemibold,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.secondary(AppTextStyles.bodyLarge),
        prefixIcon: Icon(icon, color: AppColors.textPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: AppColors.textPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: AppTextStyles.captionSmall,
      ),
      validator: validator,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyLargeSemibold,
            ),
          ],
        ),
      ),
    );
  }
}
