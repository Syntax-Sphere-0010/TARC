import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scenic_illustrations.dart';
import '../widgets/interactive_modals.dart';

class GoalsScreenTab extends StatefulWidget {
  final AppState appState;
  final VoidCallback onOpenDrawer;

  const GoalsScreenTab({
    super.key,
    required this.appState,
    required this.onOpenDrawer,
  });

  @override
  State<GoalsScreenTab> createState() => _GoalsScreenTabState();
}

class _GoalsScreenTabState extends State<GoalsScreenTab> {
  void _openAddGoalDialog() {
    HapticFeedback.mediumImpact();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedCategory = 'Academic';
    double initialProgress = 0.25;

    final isDark = widget.appState.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create New Goal',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set a custom goal manually and track your milestones',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title Field
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g. Master Statistics & Python',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.flag_rounded, color: AppTheme.primaryOrange),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target / Subtitle Field
                    TextField(
                      controller: subtitleController,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Target / Subtitle',
                        hintText: 'e.g. Read 2 chapters • Practice quizzes',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primaryOrange),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selection Chips
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Academic', 'Wellness', 'Career', 'Personal', 'Finance', 'Custom'].map((cat) {
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppTheme.primaryOrange,
                          backgroundColor: isDark ? const Color(0xFF2E241E) : const Color(0xFFF7EFE7),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.text(isDark),
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Initial Progress Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Initial Progress',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text(isDark),
                          ),
                        ),
                        Text(
                          '${(initialProgress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: initialProgress,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: AppTheme.primaryOrange,
                      onChanged: (val) => setSheetState(() => initialProgress = val),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a goal title'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final newGoal = GoalItem(
                            id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            subtitle: subtitleController.text.trim().isNotEmpty
                                ? subtitleController.text.trim()
                                : 'Created on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                            progress: initialProgress,
                            category: selectedCategory,
                            createdAt: DateTime.now(),
                          );

                          widget.appState.addGoal(newGoal);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Goal "$title" added successfully! 🎯'),
                              backgroundColor: AppTheme.primaryOrange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Add Goal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddSubjectDialog() {
    HapticFeedback.mediumImpact();
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '10:00 AM – 11:00 AM');
    final roomController = TextEditingController(text: 'Room 101');
    final instructorController = TextEditingController(text: 'Prof. Anderson');
    final isDark = widget.appState.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Custom Subject / Class',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter subject details manually. Deleted subjects will never show again.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: AppTheme.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Financial Management',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.school_rounded, color: AppTheme.primaryOrange),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  style: TextStyle(color: AppTheme.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Time Range',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.access_time_rounded, color: AppTheme.primaryOrange),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  style: TextStyle(color: AppTheme.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Room / Venue',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.place_outlined, color: AppTheme.primaryOrange),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorController,
                  style: TextStyle(color: AppTheme.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Instructor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryOrange),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newClass = ClassItem(
                        id: 'class_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        timeRange: timeController.text.trim(),
                        room: roomController.text.trim(),
                        instructor: instructorController.text.trim(),
                        cardBg: const Color(0xFFFFF6ED),
                        iconColor: const Color(0xFFE86328),
                        iconBg: const Color(0xFFFFECE0),
                        icon: Icons.menu_book_rounded,
                      );

                      widget.appState.addClass(newClass);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added subject "$title"!'),
                          backgroundColor: AppTheme.primaryOrange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Add Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteGoal(GoalItem goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to permanently delete "${goal.title}"? It will not show up anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.appState.removeGoal(goal.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${goal.title}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteClass(ClassItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete "${item.title}"? It will never show again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.appState.removeClass(item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.title}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
      body: Stack(
        children: [
          // Botanical leaf in bottom right
          Positioned(
            right: -10,
            bottom: 30,
            child: BotanicalLeafSprig(
              size: 100,
              angle: -0.4,
              color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.3) : null,
            ),
          ),
          // Botanical leaf in bottom left
          Positioned(
            left: -10,
            bottom: 50,
            child: BotanicalLeafSprig(
              size: 80,
              angle: 0.3,
              color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.3) : null,
            ),
          ),

          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: RefreshIndicator(
                  color: AppTheme.primaryOrange,
                  onRefresh: () async {
                    await widget.appState.syncGoalsWithSupabase();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // 1. Top Header with Menu, MoveRemind, dynamic Date, and badge
                      _buildTopHeader(context, isDark, now),

                      const SizedBox(height: 6),

                      // 1b. Goals Motivational Image Banner ("ONE DAY OR DAY ONE. YOU DECIDE")
                      _buildGoalsBanner(isDark),

                      const SizedBox(height: 14),

                      // 2. Goal Progress Overview Hero Card
                      _buildGoalsOverviewHero(context, isDark),

                      const SizedBox(height: 20),

                      // 3. User Goals Section with "+ Add Goal" button
                      _buildGoalsSection(context, isDark),

                      const SizedBox(height: 22),

                      // 4. Custom Subjects Section (Manual Add Type)
                      _buildCustomSubjectsSection(context, isDark),

                      const SizedBox(height: 22),

                      // 5. Handwritten quote: "Small steps every day ❤️"
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Small steps every day',
                              style: GoogleFonts.caveat(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF865538),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 13,
                              color: Color(0xFFE5572E),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab_add',
        backgroundColor: AppTheme.primaryOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openAddGoalDialog,
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark, DateTime now) {
    final dayStr = DateFormat('dd').format(now);
    final monthStr = DateFormat('MMM').format(now);

    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Hamburger Menu
          GestureDetector(
            onTap: widget.onOpenDrawer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28221D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow(isDark),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2C221B),
                size: 22,
              ),
            ),
          ),

          // Center Title + Date pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/tarc_logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TARC',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF2E2018),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$dayStr $monthStr',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),

          // Right Notification Bell
          GestureDetector(
            onTap: () => InteractiveModals.showNotificationsSheet(context, widget.appState),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28221D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow(isDark),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.primaryOrange,
                    size: 22,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5572E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsBanner(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('One day or Day One. You decide! Make today count 🎯'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/goals_banner.jpg',
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF6ED),
                      Color(0xFFFFDFBA),
                      Color(0xFFFFB37E),
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

  Widget _buildGoalsOverviewHero(BuildContext context, bool isDark) {
    final goals = widget.appState.goals;
    double avgProgress = 0.0;
    if (goals.isNotEmpty) {
      avgProgress = goals.map((g) => g.progress).reduce((a, b) => a + b) / goals.length;
    }

    final completedCount = goals.where((g) => g.progress >= 0.99).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : const Color(0xFFFFF7EF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFF6ECE0),
          width: 1.2,
        ),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -8,
            child: BotanicalLeafSprig(
              size: 70,
              angle: 0.35,
              color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.25) : null,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GOALS PROGRESS',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(avgProgress * 100).toInt()}% Achieved',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Personal Milestones',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text(isDark),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goals.length} Goals Active • $completedCount Completed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSub(isDark),
                ),
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: avgProgress,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                ),
              ),
              const SizedBox(height: 14),

              // Actions Row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.appState.setTabIndex(1); // Jump to Calendar
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Schedule',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2E2219),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2E2219),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openAddGoalDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Add Goal',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, bool isDark) {
    final goals = widget.appState.goals;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Goals',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track and manage your customized goals',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryOrange, size: 24),
                tooltip: 'Add Goal',
                onPressed: _openAddGoalDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (goals.isEmpty)
            _buildEmptyGoalsState(isDark)
          else
            ...goals.map((goal) => _buildGoalCard(context, goal, isDark)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalItem goal, bool isDark) {
    Color badgeBg;
    Color badgeColor;
    if (goal.category.toLowerCase().contains('academic')) {
      badgeBg = const Color(0xFFFFF0E6);
      badgeColor = const Color(0xFFE86328);
    } else if (goal.category.toLowerCase().contains('wellness') || goal.category.toLowerCase().contains('fitness')) {
      badgeBg = const Color(0xFFE8F7EC);
      badgeColor = const Color(0xFF388E3C);
    } else if (goal.category.toLowerCase().contains('finance')) {
      badgeBg = const Color(0xFFEDE7F6);
      badgeColor = const Color(0xFF7E57C2);
    } else {
      badgeBg = const Color(0xFFE3F2FD);
      badgeColor = const Color(0xFF1976D2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? badgeColor.withValues(alpha: 0.2) : badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.fromSchedule ? Icons.calendar_today_rounded : Icons.flag_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? badgeColor.withValues(alpha: 0.2) : badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goal.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        if (goal.fromSchedule) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'From Schedule 📅',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goal.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    if (goal.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        goal.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSub(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'Delete Goal',
                onPressed: () => _deleteGoal(goal),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSub(isDark),
                ),
              ),
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: goal.progress >= 0.99 ? Colors.green : AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF30261F) : const Color(0xFFF3EAE0),
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.progress >= 0.99 ? Colors.green : AppTheme.primaryOrange,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Increment / Decrement Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Quick Adjust: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSub(isDark),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.appState.updateGoalProgress(goal.id, goal.progress - 0.1);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('-10%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.appState.updateGoalProgress(goal.id, goal.progress + 0.1);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('+10%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.track_changes_rounded, size: 48, color: AppTheme.textSub(isDark)),
          const SizedBox(height: 10),
          Text(
            'No Goals Added Yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your goals manually or move reminders from schedule!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppTheme.textSub(isDark),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Your First Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _openAddGoalDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSubjectsSection(BuildContext context, bool isDark) {
    final classes = widget.appState.classes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Subjects & Classes',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manually add subjects. When deleted, they will never stick.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryOrange),
                tooltip: 'Add Custom Subject',
                onPressed: _openAddSubjectDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (classes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'No subjects added yet. Tap "+" to add custom subjects manually.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
              ),
            )
          else
            ...classes.map((cls) => _buildClassCard(context, cls, isDark)),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, ClassItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.timeRange} • ${item.room}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textSub(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.instructor.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Instructor: ${item.instructor}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSub(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            tooltip: 'Delete Subject',
            onPressed: () => _deleteClass(item),
          ),
        ],
      ),
    );
  }
}
