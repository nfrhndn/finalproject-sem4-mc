import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/user.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/pages/auth/sign_in_page.dart';
import 'package:padalpro/presentation/pages/bookings/my_bookings_page.dart';
import 'package:padalpro/presentation/pages/community/community_page.dart';
import 'package:padalpro/presentation/pages/profile/change_password_page.dart';
import 'package:padalpro/presentation/pages/profile/edit_profile_page.dart';
import 'package:padalpro/presentation/pages/search/search_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentNavIndex = 4; // Profile is selected

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navigate to sign in page after logout
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Black header with profile photo overlapping
                    _buildHeader(context),
                    // Profile info card overlapping header
                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: _buildProfileInfo(user),
                    ),
                    // Menu sections
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Account section
                            _buildMenuSection(
                              title: 'Account',
                              items: [
                                _MenuItem(
                                  icon: Icons.person_outline,
                                  title: 'Edit Profile',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const EditProfilePage(),
                                      ),
                                    );
                                  },
                                ),
                                _MenuItem(
                                  icon: Icons.lock_outline,
                                  title: 'Change Password',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ChangePasswordPage(),
                                      ),
                                    );
                                  },
                                ),
                                _MenuItem(
                                  icon: Icons.notifications_outlined,
                                  title: 'Notifications',
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Support section
                            _buildMenuSection(
                              title: 'Support',
                              items: [
                                _MenuItem(
                                  icon: Icons.help_outline,
                                  title: 'Help Center',
                                  onTap: () {},
                                ),
                                _MenuItem(
                                  icon: Icons.policy_outlined,
                                  title: 'Privacy Policy',
                                  onTap: () {},
                                ),
                                _MenuItem(
                                  icon: Icons.description_outlined,
                                  title: 'Terms of Service',
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Logout button
                            _buildLogoutButton(context),
                            const SizedBox(height: 16),
                            // App version
                            Text('Version 1.0.0', style: AppTextStyles.caption),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating Bottom Nav
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        70,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Text(
          'Profile',
          style: AppTextStyles.white(
            AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(User? user) {
    return Column(
      children: [
        // Profile photo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(color: AppColors.background, width: 5),
            image: user?.profilePhotoUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(user!.profilePhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user?.profilePhotoUrl == null
              ? Center(
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          user?.name ?? 'Guest',
          style: AppTextStyles.heading2.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),
        // Email
        Text(
          user?.email ?? '',
          style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.secondary(AppTextStyles.bodyLargeSemibold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildMenuItem(item),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(item.icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.heading5.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logout',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout?',
                  style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.buttonMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Close bottom sheet first
                          Navigator.pop(context);
                          // Dispatch logout event
                          context.read<AuthBloc>().add(
                            const AuthLogoutRequested(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              'Logout',
                              style: AppTextStyles.white(
                                AppTextStyles.buttonMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTextStyles.white(
                AppTextStyles.buttonMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavIcon(0, Icons.home_rounded),
              const SizedBox(width: 4),
              _buildNavIcon(3, Icons.receipt_long_outlined),
              const SizedBox(width: 4),
              _buildNavCenterButton(),
              const SizedBox(width: 4),
              _buildNavIcon(1, Icons.groups_2_outlined),
              const SizedBox(width: 4),
              _buildNavIcon(4, Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Navigate back to Browse page - pop all pages until first route
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) {
          // Navigate to Community page
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CommunityPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 150),
            ),
          );
        } else if (index == 2) {
          // Navigate to Search page with fade
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SearchPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 150),
            ),
          );
        } else if (index == 3) {
          // Navigate to My Bookings page with fade
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MyBookingsPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 150),
            ),
          );
        } else {
          setState(() {
            _currentNavIndex = index;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNavCenterButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SearchPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 150),
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.search_rounded,
          size: 26,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
