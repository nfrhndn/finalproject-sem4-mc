import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:padbro/core/theme/app_colors.dart';
import 'package:padbro/core/theme/app_text_styles.dart';
import 'package:padbro/core/utils/snackbar_helper.dart';
import 'package:padbro/presentation/pages/bookings/my_bookings_page.dart';
import 'package:padbro/presentation/pages/browse/browse_page.dart';
import 'package:padbro/presentation/pages/profile/profile_page.dart';
import 'package:padbro/presentation/pages/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  int _currentNavIndex = 1; // Scoreboard is selected
  bool _isLoading = true;
  String _selectedTab = 'Today';

  final List<String> _tabs = ['Today', 'Yesterday', 'Oldest'];

  // Matches data (loaded from local storage)
  List<Map<String, dynamic>> _matches = [];

  static const String _storageKey = 'scoreboard_matches';

  String _getTodayDateStr() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getYesterdayDateStr() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[yesterday.month - 1]} ${yesterday.day}, ${yesterday.year}';
  }

  List<Map<String, dynamic>> get _filteredMatches {
    final today = _getTodayDateStr();
    final yesterday = _getYesterdayDateStr();

    return _matches.where((match) {
      final matchDate = match['date'] as String;
      if (_selectedTab == 'Today') {
        return matchDate == today;
      } else if (_selectedTab == 'Yesterday') {
        return matchDate == yesterday;
      } else {
        // Oldest - everything except today and yesterday
        return matchDate != today && matchDate != yesterday;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString(_storageKey);

    if (storedData != null && storedData.isNotEmpty) {
      // Load existing matches from storage
      final List<dynamic> decoded = jsonDecode(storedData);
      _matches = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      // No data exists, initialize with dummy data
      _initializeDummyData();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _initializeDummyData() {
    final today = _getTodayDateStr();
    final yesterday = _getYesterdayDateStr();

    // Older dates
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    final weekAgo = now.subtract(const Duration(days: 7));

    final threeDaysAgoStr = '${months[threeDaysAgo.month - 1]} ${threeDaysAgo.day}, ${threeDaysAgo.year}';
    final fiveDaysAgoStr = '${months[fiveDaysAgo.month - 1]} ${fiveDaysAgo.day}, ${fiveDaysAgo.year}';
    final weekAgoStr = '${months[weekAgo.month - 1]} ${weekAgo.day}, ${weekAgo.year}';

    _matches = [
      // Today matches
      {
        'id': 'M001',
        'date': today,
        'team1': ['John Doe', 'Jane Smith'],
        'team2': ['Mike Brown', 'Sarah Wilson'],
        'score1': 6,
        'score2': 4,
        'status': 'Completed',
      },
      {
        'id': 'M002',
        'date': today,
        'team1': ['Alex Johnson'],
        'team2': ['Chris Lee'],
        'score1': 3,
        'score2': 6,
        'status': 'Completed',
      },
      // Yesterday matches
      {
        'id': 'M003',
        'date': yesterday,
        'team1': ['John Doe', 'Mike Brown'],
        'team2': ['Jane Smith', 'Sarah Wilson'],
        'score1': 6,
        'score2': 6,
        'status': 'Completed',
      },
      {
        'id': 'M004',
        'date': yesterday,
        'team1': ['Emma Davis', 'Olivia Martinez'],
        'team2': ['Alex Johnson', 'Chris Lee'],
        'score1': 7,
        'score2': 5,
        'status': 'Completed',
      },
      {
        'id': 'M005',
        'date': yesterday,
        'team1': ['Liam Wilson'],
        'team2': ['Noah Garcia'],
        'score1': 4,
        'score2': 6,
        'status': 'Completed',
      },
      // Older matches
      {
        'id': 'M006',
        'date': threeDaysAgoStr,
        'team1': ['John Doe', 'Emma Davis'],
        'team2': ['Mike Brown', 'Olivia Martinez'],
        'score1': 6,
        'score2': 3,
        'status': 'Completed',
      },
      {
        'id': 'M007',
        'date': fiveDaysAgoStr,
        'team1': ['Jane Smith', 'Alex Johnson'],
        'team2': ['Sarah Wilson', 'Chris Lee'],
        'score1': 5,
        'score2': 6,
        'status': 'Completed',
      },
      {
        'id': 'M008',
        'date': weekAgoStr,
        'team1': ['John Doe'],
        'team2': ['Mike Brown'],
        'score1': 6,
        'score2': 2,
        'status': 'Completed',
      },
    ];
    _saveMatches();
  }

  Future<void> _saveMatches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_matches));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(),
              // Tabs
              _buildTabs(),
              // Matches list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        children: [
                          // Match cards
                          ..._filteredMatches.map((match) => _buildMatchCard(match)),
                          // Empty state section
                          if (_filteredMatches.isEmpty) _buildEmptyState(),
                        ],
                      ),
              ),
            ],
          ),
          // FAB to add new match
          Positioned(
            right: 20,
            bottom: 110,
            child: GestureDetector(
              onTap: () => _showAddMatchSheet(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Scoreboard',
              style: AppTextStyles.white(AppTextStyles.heading1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySemibold.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final team1 = (match['team1'] as List).cast<String>();
    final team2 = (match['team2'] as List).cast<String>();
    final score1 = match['score1'] as int;
    final score2 = match['score2'] as int;
    final isTeam1Winner = score1 > score2;
    final isTeam2Winner = score2 > score1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row: Date badge and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        match['date'],
                        style: AppTextStyles.captionSmallBold.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isTeam1Winner || isTeam2Winner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 12, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          'Team ${isTeam1Winner ? '1' : '2'}',
                          style: AppTextStyles.withColor(
                            AppTextStyles.tiny,
                            const Color(0xFFE6A200),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Draw',
                      style: AppTextStyles.withColor(
                        AppTextStyles.tiny,
                        const Color(0xFFFF9800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Main content: Teams vs Score
            Row(
              children: [
                // Team 1 info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team 1',
                        style: AppTextStyles.secondary(AppTextStyles.tiny).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...team1.map((player) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isTeam1Winner ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    player,
                                    style: AppTextStyles.bodySemibold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$score1',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          color: isTeam1Winner ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: AppTextStyles.secondary(AppTextStyles.heading3).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$score2',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          color: isTeam2Winner ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Team 2 info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Team 2',
                        style: AppTextStyles.secondary(AppTextStyles.tiny).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...team2.map((player) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    player,
                                    style: AppTextStyles.bodySemibold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isTeam2Winner ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMatchSheet(BuildContext context) {
    final team1Player1Controller = TextEditingController();
    final team1Player2Controller = TextEditingController();
    final team2Player1Controller = TextEditingController();
    final team2Player2Controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'New Match',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              // Team 1
              Text(
                'TEAM 1',
                style: AppTextStyles.secondary(AppTextStyles.captionSmallBold).copyWith(
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(team1Player1Controller, 'Player 1 Name', icon: Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField(team1Player2Controller, 'Player 2 Name (Optional)', icon: Icons.person_outline),
              const SizedBox(height: 20),
              // Team 2
              Text(
                'TEAM 2',
                style: AppTextStyles.secondary(AppTextStyles.captionSmallBold).copyWith(
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(team2Player1Controller, 'Player 1 Name', icon: Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField(team2Player2Controller, 'Player 2 Name (Optional)', icon: Icons.person_outline),
              const SizedBox(height: 24),
              // Start Match button
              GestureDetector(
                onTap: () {
                  if (team1Player1Controller.text.isNotEmpty &&
                      team2Player1Controller.text.isNotEmpty) {
                    Navigator.pop(context);
                    _startMatch(
                      context,
                      [
                        team1Player1Controller.text,
                        if (team1Player2Controller.text.isNotEmpty)
                          team1Player2Controller.text,
                      ],
                      [
                        team2Player1Controller.text,
                        if (team2Player2Controller.text.isNotEmpty)
                          team2Player2Controller.text,
                      ],
                    );
                  } else {
                    SnackBarHelper.showError(context, 'Please enter at least 1 player per team');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      'Start Match',
                      style: AppTextStyles.heading4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon}) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: AppTextStyles.bodyLargeSemibold.copyWith(
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.secondary(AppTextStyles.bodyLarge),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.textPrimary, size: 20) : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
        ),
      ),
    );
  }

  void _startMatch(BuildContext context, List<String> team1, List<String> team2) {
    int score1 = 0;
    int score2 = 0;
    int elapsedSeconds = 0;
    late final stopwatch = Stopwatch()..start();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Start timer updates
          Future.delayed(const Duration(seconds: 1), () {
            if (stopwatch.isRunning) {
              setModalState(() {
                elapsedSeconds = stopwatch.elapsed.inSeconds;
              });
            }
          });

          String formatTime(int totalSeconds) {
            final minutes = totalSeconds ~/ 60;
            final seconds = totalSeconds % 60;
            return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          }

          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 120),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                // Header with live indicator and timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF74D50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF74D50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: AppTextStyles.withColor(
                              AppTextStyles.captionSmallBold,
                              const Color(0xFFF74D50),
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatTime(elapsedSeconds),
                            style: AppTextStyles.captionSemibold.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // Main scoreboard card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Teams and score row
                    Row(
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'TEAM 1',
                                style: AppTextStyles.secondary(AppTextStyles.tiny).copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...team1.map((player) => Text(
                                    player,
                                    style: AppTextStyles.white(AppTextStyles.bodySemibold),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                            ],
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$score1',
                                style: AppTextStyles.heading1.copyWith(
                                  fontSize: 36,
                                  color: score1 > score2 ? AppColors.primary : Colors.white,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  ':',
                                  style: AppTextStyles.secondary(AppTextStyles.heading1).copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$score2',
                                style: AppTextStyles.heading1.copyWith(
                                  fontSize: 36,
                                  color: score2 > score1 ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'TEAM 2',
                                style: AppTextStyles.secondary(AppTextStyles.tiny).copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...team2.map((player) => Text(
                                    player,
                                    style: AppTextStyles.white(AppTextStyles.bodySemibold),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Score control buttons
                    Row(
                      children: [
                        // Team 1 controls
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (score1 > 0) setModalState(() => score1--);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setModalState(() => score1++),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 80),
                        // Team 2 controls
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (score2 > 0) setModalState(() => score2--);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setModalState(() => score2++),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        stopwatch.stop();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.heading5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Show confirmation modal
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.transparent,
                          builder: (confirmContext) => Container(
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
                                // Icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sports_tennis_rounded,
                                    color: AppColors.textPrimary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'End Match',
                                  style: AppTextStyles.heading3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Are you sure you want to end this match?',
                                  style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(confirmContext),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Continue',
                                              style: AppTextStyles.heading5.copyWith(
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
                                          stopwatch.stop();
                                          final now = DateTime.now();
                                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                          final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

                                          setState(() {
                                            _matches.insert(0, {
                                              'id': 'M${DateTime.now().millisecondsSinceEpoch}',
                                              'date': dateStr,
                                              'team1': team1,
                                              'team2': team2,
                                              'score1': score1,
                                              'score2': score2,
                                              'status': 'Completed',
                                            });
                                          });
                                          _saveMatches();
                                          Navigator.pop(confirmContext); // Close confirmation
                                          Navigator.pop(context); // Close live match
                                          SnackBarHelper.showSuccess(context, 'Match saved!');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'End Match',
                                              style: AppTextStyles.heading5.copyWith(
                                                fontWeight: FontWeight.w600,
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            'End Match',
                            style: AppTextStyles.heading5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;

    switch (_selectedTab) {
      case 'Today':
        title = 'No matches today';
        subtitle = 'Start a new match to track your scores';
        break;
      case 'Yesterday':
        title = 'No matches yesterday';
        subtitle = 'You didn\'t play any matches yesterday';
        break;
      default:
        title = 'No older matches';
        subtitle = 'Your older match history will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no data empty state.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.secondary(AppTextStyles.bodyLarge),
          ),
        ],
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
              _buildNavIcon(1, Icons.scoreboard_outlined),
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
          // Navigate to Browse page
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const BrowsePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 150),
            ),
            (route) => false,
          );
        } else if (index == 3) {
          // Navigate to My Bookings page
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
        } else if (index == 4) {
          // Navigate to Profile page
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ProfilePage(),
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
