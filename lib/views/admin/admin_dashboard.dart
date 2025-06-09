// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// Remove this line:
// import 'package:fl_chart/fl_chart.dart';

// Add this instead if using Syncfusion:
// import 'package:syncfusion_flutter_charts/charts.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  String _selectedTimeRange = 'This Week';
  final List<String> _timeRanges = [
    'Today',
    'This Week',
    'This Month',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskListProvider);
    final usersAsync = ref.watch(userListProvider);
    final theme = Theme.of(context);
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

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      floatingActionButton:
          _showFab
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                  );
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
            onRefresh: () async {
              ref.refresh(taskListProvider);
              ref.refresh(userListProvider);
            },
            color: const Color(0xFF6C63FF),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Welcome Header
                SliverToBoxAdapter(child: _buildWelcomeHeader(greeting, date)),

                // Dashboard Tabs
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == 'pending').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final completed = tasks.where((t) => t.status == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(total, inProgress, pending, completed),

          const SizedBox(height: 24),

          // Task Progress Chart
          _buildTaskProgressChart(inProgress, pending, completed),

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
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildEnhancedSummaryCard(
          "In Progress",
          inProgress,
          const Color(0xFF6C63FF),
          Icons.timelapse_rounded,
          inProgress > 0 ? (inProgress / total * 100).toInt() : 0,
        ),
        _buildEnhancedSummaryCard(
          "Pending",
          pending,
          const Color(0xFFFF9800),
          Icons.pending_actions_rounded,
          pending > 0 ? (pending / total * 100).toInt() : 0,
        ),
        _buildEnhancedSummaryCard(
          "Completed",
          completed,
          const Color(0xFF4CAF50),
          Icons.check_circle_outline_rounded,
          completed > 0 ? (completed / total * 100).toInt() : 0,
        ),
        _buildEnhancedSummaryCard(
          "Total Tasks",
          total,
          const Color(0xFF2196F3),
          Icons.assignment_rounded,
          100,
        ),
      ],
    );
  }

  Widget _buildEnhancedSummaryCard(
    String label,
    int count,
    Color color,
    IconData icon,

    int percentage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(11),
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
              // Header row with icon and percentage
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 14),
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
              const SizedBox(height: 4),

              // Count
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              // Label
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // // Description
              // Text(
              //   description,
              //   style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskProgressChart(int inProgress, int pending, int completed) {
    final total = inProgress + pending + completed;

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
                        // Custom Donut Chart
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                children: [
                                  // Background circle
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  // Progress segments
                                  CustomPaint(
                                    size: const Size(150, 150),
                                    painter: DonutChartPainter(
                                      inProgress: inProgress,
                                      pending: pending,
                                      completed: completed,
                                      total: total,
                                    ),
                                  ),
                                  // Center text
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
                              const SizedBox(height: 16),
                              _buildChartLegendItem(
                                "Pending",
                                pending,
                                const Color(0xFFFF9800),
                              ),
                              const SizedBox(height: 16),
                              _buildChartLegendItem(
                                "Completed",
                                completed,
                                const Color(0xFF4CAF50),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              "$count tasks",
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List tasks) {
    // Sort tasks by most recent first
    final recentTasks = List.from(tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take only the 5 most recent tasks
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
                onPressed: () {
                  // Navigate to activity log
                  _tabController.animateTo(1); // Switch to Tasks tab
                },
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
                    displayTasks.map((task) {
                      return _buildActivityItem(task);
                    }).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic task) {
    // Get status color and icon
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
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab(List tasks) {
    final active = tasks.where((t) => t.status != 'completed').toList();
    final completed = tasks.where((t) => t.status == 'completed').toList();

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
                // Active Tasks
                _buildTaskList(active, isCompleted: false),

                // Completed Tasks
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                  );
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
    // Get priority color
    final priorityColor = _getPriorityColor(task.priority);

    // Get status color and icon
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
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    // Calculate due date status
    final now = DateTime.now();
    final dueDate = task.dueDate;
    final isOverdue = dueDate.isBefore(now) && task.status != 'completed';
    final isDueSoon =
        dueDate.difference(now).inDays <= 2 &&
        !isOverdue &&
        task.status != 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
          );
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
              // Task header with status and priority
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
                  ],
                ),
              ),

              // Task content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task title
                    Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.black54 : Colors.black87,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Task description (truncated)
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

                    // Task metadata
                    Row(
                      children: [
                        // Due date
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

                        // Assignees
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

        return Column(
          children: [
            // Team members list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  // Mock performance data

                  return _buildTeamMemberCard(
                    user.username,
                    user.email,
                    user.role,
                  );
                },
              ),
            ),
          ],
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
                  onPressed: () => ref.refresh(userListProvider),
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
      child: Column(
        children: [
          // Header with avatar and basic info
          Padding(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
        ],
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
              onPressed: () {
                ref.invalidate(taskListProvider);
                ref.invalidate(userListProvider);
              },
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

  // void _showNotificationsPanel() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder:
  //         (context) => Container(
  //           height: MediaQuery.of(context).size.height * 0.7,
  //           decoration: const BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //           ),
  //           child: Column(
  //             children: [
  //               // Handle bar
  //               Container(
  //                 width: 40,
  //                 height: 4,
  //                 margin: const EdgeInsets.symmetric(vertical: 12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey.shade300,
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),

  //               // Header
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 20),
  //                 child: Row(
  //                   children: [
  //                     Text(
  //                       "Notifications",
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                     TextButton(
  //                       onPressed: () {
  //                         // Mark all as read
  //                         Navigator.pop(context);
  //                       },
  //                       child: Text(
  //                         "Mark all as read",
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 12,
  //                           color: const Color(0xFF6C63FF),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               const Divider(),

  //               // Notifications list
  //               Expanded(
  //                 child: ListView(
  //                   padding: const EdgeInsets.all(20),
  //                   children: [
  //                     _buildNotificationItem(
  //                       "New Task Assigned",
  //                       "You have been assigned to 'Update Dashboard UI'",
  //                       "2 hours ago",
  //                       Icons.assignment,
  //                       Colors.blue,
  //                       isUnread: true,
  //                     ),
  //                     _buildNotificationItem(
  //                       "Task Completed",
  //                       "John Smith completed 'Fix Login Issues'",
  //                       "Yesterday",
  //                       Icons.check_circle,
  //                       Colors.green,
  //                       isUnread: true,
  //                     ),
  //                     _buildNotificationItem(
  //                       "Deadline Approaching",
  //                       "Task 'Implement User Authentication' is due tomorrow",
  //                       "Yesterday",
  //                       Icons.warning,
  //                       Colors.orange,
  //                       isUnread: true,
  //                     ),
  //                     _buildNotificationItem(
  //                       "New Comment",
  //                       "Sarah added a comment to 'Database Migration'",
  //                       "2 days ago",
  //                       Icons.comment,
  //                       Colors.purple,
  //                     ),
  //                     _buildNotificationItem(
  //                       "Task Updated",
  //                       "Priority changed for 'API Integration'",
  //                       "3 days ago",
  //                       Icons.update,
  //                       Colors.teal,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //   );
  // }

  // Widget _buildNotificationItem(
  //   String title,
  //   String message,
  //   String time,
  //   IconData icon,
  //   Color color, {
  //   bool isUnread = false,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     decoration: BoxDecoration(
  //       color: isUnread ? color.withOpacity(0.05) : Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: isUnread ? color.withOpacity(0.3) : Colors.grey.shade200,
  //       ),
  //     ),
  //     child: ListTile(
  //       contentPadding: const EdgeInsets.all(16),
  //       leading: Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: BoxDecoration(
  //           color: color.withOpacity(0.1),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Icon(icon, color: color),
  //       ),
  //       title: Row(
  //         children: [
  //           Expanded(
  //             child: Text(
  //               title,
  //               style: GoogleFonts.poppins(
  //                 fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ),
  //           if (isUnread)
  //             Container(
  //               width: 8,
  //               height: 8,
  //               decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  //             ),
  //         ],
  //       ),
  //       subtitle: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const SizedBox(height: 4),
  //           Text(
  //             message,
  //             style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             time,
  //             style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
  //           ),
  //         ],
  //       ),
  //       onTap: () {
  //         // Handle notification tap
  //         Navigator.pop(context);
  //       },
  //     ),
  //   );
  // }

  void _toggleTaskStatus(dynamic task) {
    // In a real app, this would call an API to update the task status
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          task.status == 'completed'
              ? "Task reopened successfully"
              : "Task marked as completed",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor:
            task.status == 'complete' ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
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

    if (difference == 0) {
      return "Today";
    } else if (difference == 1) {
      return "Tomorrow";
    } else if (difference > 1 && difference < 7) {
      return "In $difference days";
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class DonutChartPainter extends CustomPainter {
  final int inProgress;
  final int pending;
  final int completed;
  final int total;

  DonutChartPainter({
    required this.inProgress,
    required this.pending,
    required this.completed,
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

    // Calculate angles
    final inProgressAngle = (inProgress / total) * 2 * 3.14159;
    final pendingAngle = (pending / total) * 2 * 3.14159;
    final completedAngle = (completed / total) * 2 * 3.14159;

    double startAngle = -3.14159 / 2; // Start from top

    // Draw in progress arc
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

    // Draw pending arc
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

    // Draw completed arc
    if (completed > 0) {
      paint.color = const Color(0xFF4CAF50);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        completedAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
