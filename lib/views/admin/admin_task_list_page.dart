// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/state/auth_state.dart';
import 'package:task_flow_app/views/admin/create_task_page.dart';
import 'package:task_flow_app/views/user/task_detail_page.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../widgets/task_card.dart';
// Add this import for TaskDetailPage

class AdminTaskListPage extends ConsumerStatefulWidget {
  const AdminTaskListPage({super.key});

  @override
  ConsumerState<AdminTaskListPage> createState() => _AdminTaskListPageState();
}

class _AdminTaskListPageState extends ConsumerState<AdminTaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabLabels = [
    "All",
    "To Do",
    "In Review",
    "Completed",
    "Personal",
    "Aborted",
  ];
  final List<String> statusFilter = [
    "all",
    "pending",
    "in_progress",
    "completed",
    "personal",
    "abort",
  ];

  final Map<String, IconData> tabIcons = {
    "All": Icons.list_alt,
    "To Do": Icons.pending_actions,
    "In Review": Icons.rate_review,
    "Completed": Icons.task_alt,
    "Personal": Icons.person_pin,
    "Aborted": Icons.cancel_outlined,
  };

  final Map<String, Color> tabColors = {
    "All": Colors.deepPurple,
    "To Do": Colors.orange,
    "In Review": Colors.blue,
    "Completed": Colors.green,
    "Personal": Colors.teal,
    "Aborted": Colors.red.shade900,
  };
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks, String status) {
    if (status == "all") return tasks;
    if (status == "personal") {
      return tasks.where((t) => t.isPersonalTask).toList();
    }
    return tasks.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Manage all tasks",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Add floating action button for creating new tasks
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                );
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs:
                  tabLabels
                      .map(
                        (label) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tabIcons[label], size: 18),
                              const SizedBox(width: 8),
                              Text(label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              isScrollable: true,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: taskAsync.when(
        data:
            (tasks) => TabBarView(
              controller: _tabController,
              children:
                  statusFilter.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    final label = tabLabels[index];
                    final filtered = _filterTasks(tasks, status);

                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(taskListProvider),
                      color: Colors.deepPurple,
                      child:
                          filtered.isEmpty
                              ? _buildEmptyState(label)
                              : _buildTaskList(filtered, label),
                    );
                  }).toList(),
            ),
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
        error: (e, _) => _buildErrorState(e),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String category) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Enhanced header with gradient background
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tabColors[category]!.withOpacity(0.7),
                    tabColors[category]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tabColors[category]!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(tabIcons[category], color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$category Tasks",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'} to manage",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${tasks.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildEnhancedTaskCard(tasks[index]),
              );
            }, childCount: tasks.length),
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Added onTap callback to TaskCard
  Widget _buildEnhancedTaskCard(Task task) {
    final user = ref.read(authStateProvider).value!;
    final String currentUserId = user.id;
    final bool isAdmin = user.role == 'admin';

    return TaskCard(
      task: task,
      currentUserId: currentUserId,
      isAdmin: isAdmin,
      // ✅ FIXED: Added onTap callback for navigation
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
          ),
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tabColors[category]!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tabIcons[category],
                  size: 64,
                  color: tabColors[category]!.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No $category Tasks",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(category),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (category == "All") ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTaskPage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Create New Task"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(taskListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateMessage(String category) {
    switch (category) {
      case "All":
        return "No tasks have been created yet. Start by creating your first task to get organized.";
      case "To Do":
        return "All tasks are either in progress or completed. Great job staying on top of things!";
      case "In Review":
        return "No tasks are currently under review. Tasks will appear here when they need approval.";
      case "Completed":
        return "No tasks have been completed yet. Keep working to see your achievements here.";
      case "Aborted": // ✅ New
        return "No tasks were aborted. All tasks are moving forward!";
      default:
        return "No tasks found in this category.";
    }
  }
}
