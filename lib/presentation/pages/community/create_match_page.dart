import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/data/datasources/court_remote_datasource.dart';
import 'package:padalpro/domain/entities/court.dart';
import 'package:padalpro/domain/repositories/court_repository.dart';
import 'package:padalpro/presentation/blocs/community/community.dart';
import 'package:padalpro/presentation/pages/community/community_match_details_page.dart';

class CreateMatchPage extends StatefulWidget {
  final Court? initialCourt;

  const CreateMatchPage({super.key, this.initialCourt});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final _notesController = TextEditingController();
  late final CommunityBloc _communityBloc;
  late final CourtRepository _courtRepository;

  List<Court> _courts = [];
  List<TimeSlotModel> _slots = [];
  Court? _selectedCourt;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _skillLevel = 'beginner';
  int? _startHour;
  int? _endHour;
  bool _isLoadingCourts = true;
  bool _isLoadingSlots = false;
  String? _courtError;
  String? _slotError;

  static const _skillLevels = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _communityBloc = sl<CommunityBloc>();
    _courtRepository = sl<CourtRepository>();
    _selectedCourt = widget.initialCourt;
    _loadCourts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _communityBloc.close();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    setState(() {
      _isLoadingCourts = true;
      _courtError = null;
    });

    final result = await _courtRepository.getCourts(perPage: 30, page: 1);
    result.fold(
      (failure) {
        setState(() {
          _courtError = failure.message;
          _isLoadingCourts = false;
        });
      },
      (response) {
        final courts = <Court>[...response.courts];
        final initialCourt = widget.initialCourt;
        if (initialCourt != null &&
            !courts.any((court) => court.id == initialCourt.id)) {
          courts.insert(0, initialCourt);
        }
        final selectedCourt = initialCourt == null
            ? (_selectedCourt ?? (courts.isNotEmpty ? courts.first : null))
            : courts.firstWhere((court) => court.id == initialCourt.id);
        setState(() {
          _courts = courts;
          _selectedCourt = selectedCourt;
          _isLoadingCourts = false;
        });
        if (_selectedCourt != null) {
          _loadSlots();
        }
      },
    );
  }

  Future<void> _loadSlots() async {
    final court = _selectedCourt;
    if (court == null) return;

    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
      _slots = [];
      _startHour = null;
      _endHour = null;
    });

    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await _courtRepository.getAvailableSlots(court.id, date);
    result.fold(
      (failure) {
        setState(() {
          _slotError = failure.message;
          _isLoadingSlots = false;
        });
      },
      (response) {
        setState(() {
          _slots = response.slots.where((slot) => slot.available).toList();
          _isLoadingSlots = false;
        });
      },
    );
  }

  void _submit() {
    final court = _selectedCourt;
    final startHour = _startHour;
    final endHour = _endHour;
    if (court == null || startHour == null || endHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose court and time first')),
      );
      return;
    }

    _communityBloc.add(
      CommunityOpenMatchCreateRequested(
        courtId: court.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startHour: startHour,
        endHour: endHour,
        skillLevel: _skillLevel,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _communityBloc,
      child: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is CommunityMatchDetailsLoaded) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CommunityMatchDetailsPage(matchId: state.match.id),
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is CommunityActionLoading;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 16,
                    16,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildCourtPicker(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _buildTimePicker(),
                      const SizedBox(height: 16),
                      _buildSkillPicker(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 28,
                  child: _buildSubmitButton(isSubmitting),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Open Match', style: AppTextStyles.heading2),
              Text('Open slots for 4 players', style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading4),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCourtPicker() {
    return _buildSection(
      title: 'Court',
      child: _isLoadingCourts
          ? const Center(child: CircularProgressIndicator())
          : _courtError != null
          ? _buildInlineError(_courtError!, _loadCourts)
          : DropdownButtonFormField<Court>(
              key: ValueKey('court-${_selectedCourt?.id ?? 'none'}'),
              initialValue: _selectedCourt,
              decoration: _inputDecoration(),
              isExpanded: true,
              items: _courts
                  .map(
                    (court) => DropdownMenuItem(
                      value: court,
                      child: Text(court.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: widget.initialCourt != null
                  ? null
                  : (court) {
                      setState(() => _selectedCourt = court);
                      _loadSlots();
                    },
            ),
    );
  }

  Widget _buildDatePicker() {
    final dates = List.generate(
      10,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );
    return _buildSection(
      title: 'Date',
      child: SizedBox(
        height: 62,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final date = dates[index];
            final isSelected = DateUtils.isSameDay(date, _selectedDate);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
                _loadSlots();
              },
              child: Container(
                width: 78,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: isSelected
                          ? AppTextStyles.white(AppTextStyles.captionSemibold)
                          : AppTextStyles.captionSemibold,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM').format(date),
                      style: isSelected
                          ? AppTextStyles.white(AppTextStyles.caption)
                          : AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    if (_isLoadingSlots) {
      return _buildSection(
        title: 'Time',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_slotError != null) {
      return _buildSection(
        title: 'Time',
        child: _buildInlineError(_slotError!, _loadSlots),
      );
    }

    if (_slots.isEmpty) {
      return _buildSection(
        title: 'Time',
        child: Text(
          'No available slots for this court and date.',
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    final hours = _slots.map((slot) => _hourFromSlot(slot.time)).toList();
    final endOptions = _startHour == null
        ? <int>[]
        : _endOptionsFor(_startHour!, hours);

    return _buildSection(
      title: 'Time',
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey(
                'start-${_selectedCourt?.id}-${_selectedDate.toIso8601String()}-${_startHour ?? 'none'}',
              ),
              initialValue: _startHour,
              decoration: _inputDecoration(label: 'Start'),
              items: hours
                  .map(
                    (hour) => DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    ),
                  )
                  .toList(),
              onChanged: (hour) {
                setState(() {
                  _startHour = hour;
                  final nextEndOptions = hour == null
                      ? <int>[]
                      : _endOptionsFor(hour, hours);
                  _endHour = nextEndOptions.isEmpty
                      ? null
                      : nextEndOptions.first;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey(
                'end-${_startHour ?? 'none'}-${_endHour ?? 'none'}',
              ),
              initialValue: _endHour,
              decoration: _inputDecoration(label: 'End'),
              items: endOptions
                  .map(
                    (hour) => DropdownMenuItem(
                      value: hour,
                      child: Text('${hour.toString().padLeft(2, '0')}:00'),
                    ),
                  )
                  .toList(),
              onChanged: (hour) => setState(() => _endHour = hour),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillPicker() {
    return _buildSection(
      title: 'Skill Level',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _skillLevels.map((level) {
          final isSelected = _skillLevel == level;
          return GestureDetector(
            onTap: () => setState(() => _skillLevel = level),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _titleCase(level),
                style: isSelected
                    ? AppTextStyles.white(AppTextStyles.bodySemibold)
                    : AppTextStyles.bodySemibold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesField() {
    return _buildSection(
      title: 'Notes',
      child: TextField(
        controller: _notesController,
        minLines: 3,
        maxLines: 5,
        decoration: _inputDecoration(
          hint: 'Optional: match preference, friendly level, or reminder.',
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    return GestureDetector(
      onTap: isSubmitting ? null : _submit,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSubmitting ? AppColors.textSecondary : AppColors.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Publish Open Match', style: AppTextStyles.buttonLarge),
        ),
      ),
    );
  }

  Widget _buildInlineError(String message, VoidCallback onRetry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTextStyles.error),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onRetry,
          child: Text('Retry', style: AppTextStyles.link),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  int _hourFromSlot(String time) {
    return int.tryParse(time.split(':').first) ?? 0;
  }

  List<int> _endOptionsFor(int startHour, List<int> availableStartHours) {
    final available = availableStartHours.toSet();
    final options = <int>[];
    var nextEnd = startHour + 1;
    while (available.contains(nextEnd - 1)) {
      options.add(nextEnd);
      nextEnd++;
    }
    return options;
  }

  String _titleCase(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }
}
