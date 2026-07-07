import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/core/utils/snackbar_helper.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/pages/browse/browse_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    context.read<AuthBloc>().add(
      AuthChangePasswordRequested(
        currentPassword: '',
        newPassword: _passwordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _submitted = false);
          SnackBarHelper.showError(context, state.message);
        }
        if (_submitted && state is AuthAuthenticated) {
          SnackBarHelper.showSuccess(context, 'Password berhasil diperbarui.');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const BrowsePage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Set New Password', style: AppTextStyles.heading1),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan password baru untuk akun PadalPro kamu.',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('New Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggle: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Password confirmation does not match';
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: AppTextStyles.buttonLarge,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: AppTextStyles.bodySemibold);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Enter password',
        hintStyle: AppTextStyles.secondary(AppTextStyles.bodyLarge),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.textPrimary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your new password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
    );
  }
}
