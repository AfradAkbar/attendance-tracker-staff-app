import 'package:flutter/material.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';

class HodTimetableScreen extends StatefulWidget {
  const HodTimetableScreen({super.key});

  @override
  State<HodTimetableScreen> createState() => _HodTimetableScreenState();
}

class _HodTimetableScreenState extends State<HodTimetableScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color surfaceColor = Color(0xFFF8F6F4);

  List<Map<String, dynamic>> batches = [];
  Map<String, dynamic>? selectedBatch;
  int? selectedSemester;

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> staffList = [];

  // grid[dayOfWeek 1-5][hour 1-5] = { subject_id, subject_name, staff_id, staff_name }
  Map<int, Map<int, Map<String, String>>> grid = {};

  bool isLoadingBatches = true;
  bool isLoadingData = false;
  bool isSaving = false;

  late TabController _tabController;

  static const List<String> _dayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initGrid();
    _loadBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initGrid() {
    final g = <int, Map<int, Map<String, String>>>{};
    for (int d = 1; d <= 5; d++) {
      g[d] = {};
      for (int h = 1; h <= 5; h++) {
        g[d]![h] = {
          'subject_id': '',
          'subject_name': '',
          'staff_id': '',
          'staff_name': '',
        };
      }
    }
    grid = g;
  }

  Future<void> _loadBatches() async {
    setState(() => isLoadingBatches = true);
    try {
      final data = await ApiService.get(kHodBatches);
      if (data != null && data['success'] == true) {
        setState(() {
          batches = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading batches: $e');
    } finally {
      setState(() => isLoadingBatches = false);
    }
  }

  Future<void> _loadTimetableData() async {
    if (selectedBatch == null || selectedSemester == null) return;
    setState(() {
      isLoadingData = true;
      subjects = [];
      staffList = [];
      _initGrid();
    });

    try {
      final batchId = selectedBatch!['_id'].toString();
      final sem = selectedSemester.toString();

      // Load subjects, staff, and existing timetable in parallel
      final results = await Future.wait([
        ApiService.get('$kHodSubjects?batch_id=$batchId&semester=$sem'),
        ApiService.get(kHodDepartmentStaff),
        ApiService.get('$kHodTimetable/$batchId?semester=$sem'),
      ]);

      final subjectRes = results[0];
      final staffRes = results[1];
      final timetableRes = results[2];

      setState(() {
        if (subjectRes != null && subjectRes['success'] == true) {
          subjects = List<Map<String, dynamic>>.from(subjectRes['data'] ?? []);
        }
        if (staffRes != null && staffRes['success'] == true) {
          staffList = List<Map<String, dynamic>>.from(staffRes['data'] ?? []);
        }
        if (timetableRes != null && timetableRes['success'] == true) {
          final slots = List<Map<String, dynamic>>.from(
            timetableRes['data'] ?? [],
          );
          for (final slot in slots) {
            final day = (slot['dayOfWeek'] as num?)?.toInt() ?? 0;
            final hour = (slot['hour'] as num?)?.toInt() ?? 0;
            if (day >= 1 && day <= 5 && hour >= 1 && hour <= 5) {
              grid[day]![hour] = {
                'subject_id': slot['subject_id']?.toString() ?? '',
                'subject_name': slot['subject_name']?.toString() ?? '',
                'staff_id': slot['staff_id']?.toString() ?? '',
                'staff_name': slot['staff_name']?.toString() ?? '',
              };
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading timetable data: $e');
    } finally {
      if (mounted) setState(() => isLoadingData = false);
    }
  }

  Future<void> _saveTimetable() async {
    if (selectedBatch == null || selectedSemester == null) return;

    // Collect filled entries
    final entries = <Map<String, dynamic>>[];
    for (int d = 1; d <= 5; d++) {
      for (int h = 1; h <= 5; h++) {
        final cell = grid[d]![h]!;
        if (cell['subject_id']!.isNotEmpty) {
          entries.add({
            'dayOfWeek': d,
            'hour': h,
            'subject_id': cell['subject_id'],
            if (cell['staff_id']!.isNotEmpty) 'staff_id': cell['staff_id'],
          });
        }
      }
    }

    setState(() => isSaving = true);
    try {
      final result = await ApiService.post(kSaveHodTimetable, {
        'batch_id': selectedBatch!['_id'].toString(),
        'semester_number': selectedSemester,
        'entries': entries,
      });

      if (!mounted) return;
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Timetable saved!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save timetable. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ─── Slot editor bottom sheet ─────────────────────────────────────────────

  void _editSlot(int day, int hour) {
    final initial = Map<String, String>.from(grid[day]![hour]!);
    String tempSubjectId = initial['subject_id']!;
    String tempSubjectName = initial['subject_name']!;
    String tempStaffId = initial['staff_id']!;
    String tempStaffName = initial['staff_name']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'P$hour',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_dayLabels[day - 1]}  ·  Period $hour',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (tempSubjectId.isNotEmpty)
                      TextButton(
                        onPressed: () => setSheet(() {
                          tempSubjectId = '';
                          tempSubjectName = '';
                          tempStaffId = '';
                          tempStaffName = '';
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subject picker
                _pickerLabel('Subject'),
                const SizedBox(height: 8),
                _pickerTile(
                  icon: Icons.menu_book_outlined,
                  value: tempSubjectName,
                  placeholder: 'Tap to select subject',
                  onTap: () async {
                    final res = await _showItemPicker(
                      ctx,
                      title: 'Select Subject',
                      items: subjects,
                      idKey: '_id',
                      nameKey: 'subject_name',
                      selectedId: tempSubjectId,
                    );
                    if (res != null) {
                      setSheet(() {
                        tempSubjectId = res['id']!;
                        tempSubjectName = res['name']!;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Staff picker
                _pickerLabel('Staff  (optional)'),
                const SizedBox(height: 8),
                _pickerTile(
                  icon: Icons.person_outline,
                  value: tempStaffName,
                  placeholder: 'Tap to select staff',
                  onTap: () async {
                    final res = await _showItemPicker(
                      ctx,
                      title: 'Select Staff',
                      items: staffList,
                      idKey: '_id',
                      nameKey: 'name',
                      selectedId: tempStaffId,
                      allowClear: true,
                    );
                    if (res != null) {
                      setSheet(() {
                        tempStaffId = res['id']!;
                        tempStaffName = res['name']!;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: tempSubjectId.isEmpty
                        ? null
                        : () {
                            setState(() {
                              grid[day]![hour] = {
                                'subject_id': tempSubjectId,
                                'subject_name': tempSubjectName,
                                'staff_id': tempStaffId,
                                'staff_name': tempStaffName,
                              };
                            });
                            Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
      letterSpacing: 0.4,
    ),
  );

  Widget _pickerTile({
    required IconData icon,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : placeholder,
              style: TextStyle(
                fontSize: 14,
                color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
        ],
      ),
    ),
  );

  Future<Map<String, String>?> _showItemPicker(
    BuildContext ctx, {
    required String title,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    String selectedId = '',
    bool allowClear = false,
  }) => showDialog<Map<String, String>>(
    context: ctx,
    builder: (dCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dCtx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (allowClear)
                  ListTile(
                    leading: const Icon(
                      Icons.do_not_disturb_alt,
                      color: Colors.red,
                      size: 20,
                    ),
                    title: const Text(
                      'None',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => Navigator.pop(dCtx, {'id': '', 'name': ''}),
                  ),
                ...items.map((item) {
                  final id = item[idKey]?.toString() ?? '';
                  final name = item[nameKey]?.toString() ?? '';
                  final selected = id == selectedId;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? primaryColor : Colors.grey.shade400,
                      size: 20,
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    onTap: () => Navigator.pop(dCtx, {'id': id, 'name': name}),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  // ─── Batch / Semester pickers ─────────────────────────────────────────────

  void _showBatchPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.70,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Select Batch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: batches.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No batches found in your department.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: batches.length,
                          itemBuilder: (_, i) {
                            final b = batches[i];
                            final sel = selectedBatch?['_id'] == b['_id'];
                            return ListTile(
                              leading: Icon(
                                sel
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: sel
                                    ? primaryColor
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              title: Text(b['name']?.toString() ?? ''),
                              subtitle: b['current_semester'] != null
                                  ? Text(
                                      'Current: Semester ${b['current_semester']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  selectedBatch = b;
                                  selectedSemester = null;
                                  subjects = [];
                                  staffList = [];
                                  _initGrid();
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSemesterPicker() {
    if (selectedBatch == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.70,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Select Semester',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 6,
                    itemBuilder: (_, i) {
                      final sem = i + 1;
                      final sel = selectedSemester == sem;
                      final isCurrent =
                          selectedBatch?['current_semester'] == sem;
                      return ListTile(
                        leading: Icon(
                          sel
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: sel ? primaryColor : Colors.grey.shade400,
                          size: 20,
                        ),
                        title: Text('Semester $sem'),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => selectedSemester = sem);
                          _loadTimetableData();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isReady =
        selectedBatch != null && selectedSemester != null && !isLoadingData;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Timetable Editor'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (selectedBatch != null && selectedSemester != null)
            isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _saveTimetable,
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
        ],
      ),
      body: Column(
        children: [
          _buildSelectors(),
          if (isLoadingData)
            LinearProgressIndicator(
              color: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.15),
            ),
          if (isReady) ...[
            _buildDayTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(5, (i) => _buildDayView(i + 1)),
              ),
            ),
          ] else if (!isLoadingData)
            Expanded(child: _buildEmptyHint()),
        ],
      ),
    );
  }

  Widget _buildSelectors() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Column(
      children: [
        _selectorTile(
          icon: Icons.class_outlined,
          label: selectedBatch != null
              ? selectedBatch!['name']?.toString() ?? 'Batch'
              : isLoadingBatches
              ? 'Loading batches…'
              : 'Select Batch',
          hasValue: selectedBatch != null,
          onTap: isLoadingBatches ? null : _showBatchPicker,
        ),
        const SizedBox(height: 10),
        _selectorTile(
          icon: Icons.calendar_view_month_outlined,
          label: selectedSemester != null
              ? 'Semester $selectedSemester'
              : 'Select Semester',
          hasValue: selectedSemester != null,
          disabled: selectedBatch == null,
          onTap: selectedBatch == null ? null : _showSemesterPicker,
        ),
      ],
    ),
  );

  Widget _selectorTile({
    required IconData icon,
    required String label,
    required bool hasValue,
    VoidCallback? onTap,
    bool disabled = false,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade50 : surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: disabled
                ? Colors.grey.shade300
                : hasValue
                ? primaryColor
                : Colors.grey.shade500,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: hasValue ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
          ),
          Icon(Icons.expand_more, color: Colors.grey.shade400, size: 20),
        ],
      ),
    ),
  );

  Widget _buildDayTabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabController,
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey.shade500,
      indicatorColor: primaryColor,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: _dayShort.map((d) => Tab(text: d)).toList(),
    ),
  );

  Widget _buildDayView(int day) {
    // Count filled periods for this day
    final filled = List.generate(
      5,
      (h) => grid[day]![h + 1]!['subject_id']!,
    ).where((s) => s.isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Day summary chip
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                _dayLabels[day - 1],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: filled > 0
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$filled / 5 periods assigned',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: filled > 0 ? primaryColor : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Period cards
        ...List.generate(5, (i) => _buildPeriodCard(day, i + 1)),
      ],
    );
  }

  Widget _buildPeriodCard(int day, int hour) {
    final cell = grid[day]![hour]!;
    final hasSubject = cell['subject_id']!.isNotEmpty;
    final hasStaff = cell['staff_id']!.isNotEmpty;

    return GestureDetector(
      onTap: subjects.isEmpty ? null : () => _editSlot(day, hour),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSubject
                ? primaryColor.withOpacity(0.35)
                : Colors.grey.shade100,
            width: hasSubject ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Period number badge
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: hasSubject
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$hour',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: hasSubject ? primaryColor : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: hasSubject
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell['subject_name']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (hasStaff) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cell['staff_name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  : Text(
                      subjects.isEmpty ? 'No subjects loaded' : 'Tap to assign',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontStyle: subjects.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
            ),
            Icon(
              hasSubject ? Icons.edit_outlined : Icons.add_circle_outline,
              color: hasSubject ? primaryColor : Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Select a batch and semester\nto manage the timetable',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}
