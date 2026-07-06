import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/blocs/community/community.dart';
import 'package:padalpro/presentation/pages/auth/sign_in_page.dart';
import 'package:padalpro/presentation/pages/bookings/my_bookings_page.dart';
import 'package:padalpro/presentation/pages/browse/browse_page.dart';
import 'package:padalpro/presentation/pages/community/community_match_details_page.dart';
import 'package:padalpro/presentation/pages/community/create_match_page.dart';
import 'package:padalpro/presentation/pages/profile/profile_page.dart';
import 'package:padalpro/presentation/pages/search/search_page.dart';
import 'package:padalpro/presentation/widgets/widgets.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final CommunityBloc _communityBloc;
  String? _selectedSkillLevel;

  static const _skillFilters = <String?>[
    null,
    'beginner',
    'intermediate',
    'advanced',
  ];

  @override
  void initState() {
    super.initState();
    _communityBloc = sl<CommunityBloc>();
    _fetchMatches();
  }

  @override
  void dispose() {
    _communityBloc.close();
    super.dispose();
  }

  void _fetchMatches() {
    _communityBloc.add(
      CommunityMatchesFetchRequested(skillLevel: _selectedSkillLevel),
    );
  }

  bool _isAuthenticated() {
    return context.read<AuthBloc>().state is AuthAuthenticated;
  }

  Future<void> _openCreateMatch() async {
    if (!_isAuthenticated()) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMatchPage()),
    );
    _fetchMatches();
  }

  Future<void> _openDetails(int matchId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityMatchDetailsPage(matchId: matchId),
      ),
    );
    _fetchMatches();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _communityBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => _fetchMatches(),
              color: AppColors.textPrimary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildFilters()),
                  BlocBuilder<CommunityBloc, CommunityState>(
                    builder: (context, state) {
                      if (state is CommunityLoading) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (state is CommunityError) {
                        final needsSetup = state.message.startsWith(
                          'Community backend belum tersedia',
                        );
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(
                            icon: needsSetup
                                ? Icons.storage_outlined
                                : Icons.error_outline_rounded,
                            title: needsSetup
                                ? 'Community setup required'
                                : 'Community failed to load',
                            message: state.message,
                            actionLabel: 'Retry',
                            onActionTap: _fetchMatches,
                          ),
                        );
                      }

                      if (state is CommunityMatchesLoaded) {
                        if (state.matches.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(
                              icon: Icons.groups_2_outlined,
                              title: 'No open matches yet',
                              message:
                                  'Create the first open match and invite players to split the court.',
                              actionLabel: 'Create Match',
                              onActionTap: _openCreateMatch,
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 170),
                          sliver: SliverList.builder(
                            itemCount: state.matches.length,
                            itemBuilder: (context, index) {
                              final match = state.matches[index];
                              return CommunityMatchCard(
                                match: match,
                                onTap: () => _openDetails(match.id),
                              );
                            },
                          ),
                        );
                      }

                      return const SliverToBoxAdapter(
                        child: SizedBox(height: 240),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(right: 16, bottom: 104, child: _buildCreateButton()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: 1,
                onHomeTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const BrowsePage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 150),
                    ),
                    (route) => false,
                  );
                },
                onBookingsTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const MyBookingsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
                onSearchTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SearchPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
                onCommunityTap: _fetchMatches,
                onProfileTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ProfilePage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 150),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: AppTextStyles.white(AppTextStyles.heading1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find players, fill courts, and split the bill.',
                  style: AppTextStyles.white(
                    AppTextStyles.body,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchMatches,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final value = _skillFilters[index];
          final isSelected = value == _selectedSkillLevel;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSkillLevel = value);
              _fetchMatches();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                value == null ? 'All' : _titleCase(value),
                style: isSelected
                    ? AppTextStyles.white(AppTextStyles.bodySemibold)
                    : AppTextStyles.bodySemibold,
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: _skillFilters.length,
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _openCreateMatch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text('Create Match', style: AppTextStyles.buttonSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                actionLabel,
                style: AppTextStyles.white(AppTextStyles.buttonSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }
}
