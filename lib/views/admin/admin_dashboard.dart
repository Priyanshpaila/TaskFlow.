// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../admin/create_task_page.dart';
import '../widgets/admin_drawer.dart';
import '../user/task_detail_page.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // Hide FAB when scrolling down, show when scrolling up
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFab) {
          setState(() => _showFab = false);
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFab) {
          setState(() => _showFab = true);
        }
      }
    });

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ FIXED: Proper data refresh method
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Force refresh both providers
      await Future.wait([
        ref.refresh(taskListProvider.future),
        ref.refresh(userListProvider.future),
      ]);

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error refreshing data: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _refreshData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Watch providers with proper error handling
    final taskAsync = ref.watch(taskListProvider);
    final usersAsync = ref.watch(userListProvider);

    final now = DateTime.now();
    final greeting = _getGreeting();
    final date = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          // ✅ ADDED: Manual refresh button
          IconButton(
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      floatingActionButton:
          _showFab
              ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                  );
                  // ✅ FIXED: Refresh data after creating task
                  if (result == true) {
                    _refreshData();
                  }
                },
                backgroundColor: const Color(0xFF6C63FF),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'New Task',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              )
              : null,
      body: taskAsync.when(
        data: (tasks) {
          return RefreshIndicator(
            onRefresh: _refreshData, // ✅ FIXED: Use proper refresh method
            color: const Color(0xFF6C63FF),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Welcome Header
                SliverToBoxAdapter(child: _buildWelcomeHeader(greeting, date)),

                // ✅ ADDED: Data freshness indicator
                if (_isRefreshing)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Updating data...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Dashboard Tabs
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF6C63FF),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF6C63FF),
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Tasks'),
                        Tab(text: 'Team'),
                      ],
                    ),
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview Tab
                      _buildOverviewTab(tasks, usersAsync),

                      // Tasks Tab
                      _buildTasksTab(tasks),

                      // Team Tab
                      _buildTeamTab(usersAsync),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
        error: (e, _) => _buildErrorState(e),
      ),
    );
  }

  Widget _buildWelcomeHeader(String greeting, String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
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

  Widget _buildOverviewTab(List tasks, AsyncValue usersAsync) {
    // ✅ FIXED: Ensure proper task counting with null safety
    final total = tasks.length;
    final pending = tasks.where((t) => t?.status == 'pending').length;
    final inProgress = tasks.where((t) => t?.status == 'in_progress').length;
    final completed = tasks.where((t) => t?.status == 'completed').length;
    final abort = tasks.where((t) => t?.status == 'abort').length;
    final forward = tasks.where((t) => t?.status == 'forward').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(
            total,
            inProgress,
            pending,
            completed,
            abort,
            forward,
          ),

          const SizedBox(height: 24),

          // Task Progress Chart
          _buildTaskProgressChart(
            inProgress,
            pending,
            completed,
            abort,
            forward,
          ),

          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(tasks),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    int total,
    int inProgress,
    int pending,
    int completed,
    int abort,
    int forward,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;

        if (isDesktop) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "In Progress",
                      inProgress,
                      const Color(0xFF6C63FF),
                      Icons.timelapse_rounded,
                      total > 0 ? (inProgress / total * 100).toInt() : 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Pending",
                      pending,
                      const Color(0xFFFF9800),
                      Icons.pending_actions_rounded,
                      total > 0 ? (pending / total * 100).toInt() : 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Completed",
                      completed,
                      const Color(0xFF4CAF50),
                      Icons.check_circle_outline_rounded,
                      total > 0 ? (completed / total * 100).toInt() : 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Forwarded",
                      forward,
                      const Color(0xFF2196F3),
                      Icons.forward_outlined,
                      total > 0 ? (forward / total * 100).toInt() : 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Aborted",
                      abort,
                      const Color(0xFFF44336),
                      Icons.cancel_outlined,
                      total > 0 ? (abort / total * 100).toInt() : 0,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "In Progress",
                      inProgress,
                      const Color(0xFF6C63FF),
                      Icons.timelapse_rounded,
                      total > 0 ? (inProgress / total * 100).toInt() : 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Pending",
                      pending,
                      const Color(0xFFFF9800),
                      Icons.pending_actions_rounded,
                      total > 0 ? (pending / total * 100).toInt() : 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Completed",
                      completed,
                      const Color(0xFF4CAF50),
                      Icons.check_circle_outline_rounded,
                      total > 0 ? (completed / total * 100).toInt() : 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Forwarded",
                      forward,
                      const Color(0xFF2196F3),
                      Icons.forward_outlined,
                      total > 0 ? (forward / total * 100).toInt() : 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedSummaryCard(
                      "Aborted",
                      abort,
                      const Color(0xFFF44336),
                      Icons.cancel_outlined,
                      total > 0 ? (abort / total * 100).toInt() : 0,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildEnhancedSummaryCard(
    String label,
    int count,
    Color color,
    IconData icon,
    int percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16), // ✅ FIXED: Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                "$percentage%",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressChart(
    int inProgress,
    int pending,
    int completed,
    int abort,
    int forward,
  ) {
    final total = inProgress + pending + completed + abort + forward;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Task Progress",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Distribution of tasks by status",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child:
                total > 0
                    ? Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  CustomPaint(
                                    size: const Size(150, 150),
                                    painter: DonutChartPainter(
                                      inProgress: inProgress,
                                      pending: pending,
                                      completed: completed,
                                      abort: abort,
                                      forward: forward,
                                      total: total,
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          total.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Total Tasks",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildChartLegendItem(
                                "In Progress",
                                inProgress,
                                const Color(0xFF6C63FF),
                              ),
                              const SizedBox(height: 12),
                              _buildChartLegendItem(
                                "Pending",
                                pending,
                                const Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 12),
                              _buildChartLegendItem(
                                "Completed",
                                completed,
                                const Color(0xFF4CAF50),
                              ),
                              const SizedBox(height: 12),
                              _buildChartLegendItem(
                                "Aborted",
                                abort,
                                const Color(0xFFF44336),
                              ),
                              const SizedBox(height: 12),
                              _buildChartLegendItem(
                                "Forwarded",
                                forward,
                                const Color(0xFF2196F3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No task data available",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
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

  Widget _buildChartLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              "$count tasks",
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List tasks) {
    final recentTasks = List.from(tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayTasks = recentTasks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activity",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text(
                  "View All",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          displayTasks.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No recent activity",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children:
                    displayTasks
                        .map((task) => _buildActivityItem(task))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic task) {
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case 'in_progress':
        statusColor = const Color(0xFF6C63FF);
        statusIcon = Icons.timelapse_rounded;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'abort':
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'forward':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.forward_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
          );
          // ✅ FIXED: Refresh after viewing task details
          if (result == true) {
            _refreshData();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAgo(task.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getPriorityColor(task.priority),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (task.status != 'completed' && task.status != 'abort')
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateTaskPage(editTask: task),
                          ),
                        );
                        // ✅ FIXED: Refresh after editing task
                        if (result == true) {
                          _refreshData();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF6C63FF),
                        ),
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

  Widget _buildTasksTab(List tasks) {
    final active =
        tasks
            .where(
              (t) =>
                  t?.status != 'completed' &&
                  t?.status != 'abort' &&
                  t?.status != 'forward',
            )
            .toList();
    final completed = tasks.where((t) => t?.status == 'completed').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF6C63FF),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: "Active (${active.length})"),
                Tab(text: "Completed (${completed.length})"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskList(active, isCompleted: false),
                _buildTaskList(completed, isCompleted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List tasks, {bool isCompleted = false}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle_outline
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? "No completed tasks yet" : "No active tasks",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (!isCompleted)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                  );
                  if (result == true) {
                    _refreshData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Create Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildEnhancedTaskItem(context, task, isCompleted: isCompleted);
      },
    );
  }

  Widget _buildEnhancedTaskItem(
    BuildContext context,
    dynamic task, {
    bool isCompleted = false,
  }) {
    final priorityColor = _getPriorityColor(task.priority);

    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case 'in_progress':
        statusColor = const Color(0xFF6C63FF);
        statusIcon = Icons.timelapse_rounded;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'abort':
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'forward':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.forward_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    final now = DateTime.now();
    final dueDate = task.dueDate;
    final isOverdue =
        dueDate.isBefore(now) &&
        task.status != 'completed' &&
        task.status != 'abort' &&
        task.status != 'forward';
    final isDueSoon =
        dueDate.difference(now).inDays <= 2 &&
        !isOverdue &&
        task.status != 'completed' &&
        task.status != 'abort' &&
        task.status != 'forward';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
          );
          if (result == true) {
            _refreshData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border:
                isOverdue
                    ? Border.all(color: Colors.red, width: 2)
                    : isDueSoon
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      task.status.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.status != 'completed' && task.status != 'abort')
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CreateTaskPage(editTask: task),
                                ),
                              );
                              if (result == true) {
                                _refreshData();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            (isCompleted ||
                                    task.status == 'abort' ||
                                    task.status == 'forward')
                                ? Colors.black54
                                : Colors.black87,
                        decoration:
                            (isCompleted ||
                                    task.status == 'abort' ||
                                    task.status == 'forward')
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description.length > 100
                          ? '${task.description.substring(0, 100)}...'
                          : task.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      isOverdue
                                          ? Colors.red.withOpacity(0.1)
                                          : isDueSoon
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color:
                                      isOverdue
                                          ? Colors.red
                                          : isDueSoon
                                          ? Colors.orange
                                          : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Due Date",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatDueDate(task.dueDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isOverdue
                                                ? Colors.red
                                                : isDueSoon
                                                ? Colors.orange
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.people_outline_rounded,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Assignees",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    "${task.assignedTo.length} member${task.assignedTo.length > 1 ? 's' : ''}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildTeamTab(AsyncValue usersAsync) {
    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "No team members found",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildTeamMemberCard(user.username, user.email, user.role);
          },
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
      error:
          (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  "Failed to load team data",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTeamMemberCard(String name, String email, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Try Again",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Tomorrow";
    if (difference > 1 && difference < 7) return "In $difference days";
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return DateFormat('MMM d').format(dateTime);
  }
}

class DonutChartPainter extends CustomPainter {
  final int inProgress;
  final int pending;
  final int completed;
  final int abort;
  final int forward;
  final int total;

  DonutChartPainter({
    required this.inProgress,
    required this.pending,
    required this.completed,
    required this.abort,
    required this.forward,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 20.0;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final inProgressAngle = (inProgress / total) * 2 * 3.14159;
    final pendingAngle = (pending / total) * 2 * 3.14159;
    final completedAngle = (completed / total) * 2 * 3.14159;
    final abortedAngle = (abort / total) * 2 * 3.14159;
    final forwardedAngle = (forward / total) * 2 * 3.14159;

    double startAngle = -3.14159 / 2;

    if (inProgress > 0) {
      paint.color = const Color(0xFF6C63FF);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        inProgressAngle,
        false,
        paint,
      );
      startAngle += inProgressAngle;
    }

    if (pending > 0) {
      paint.color = const Color(0xFFFF9800);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        pendingAngle,
        false,
        paint,
      );
      startAngle += pendingAngle;
    }

    if (completed > 0) {
      paint.color = const Color(0xFF4CAF50);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        completedAngle,
        false,
        paint,
      );
      startAngle += completedAngle;
    }

    if (abort > 0) {
      paint.color = const Color(0xFFF44336);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        abortedAngle,
        false,
        paint,
      );
      startAngle += abortedAngle;
    }

    if (forward > 0) {
      paint.color = const Color(0xFF2196F3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        forwardedAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
