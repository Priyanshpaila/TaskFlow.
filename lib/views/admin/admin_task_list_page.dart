import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/views/admin/create_task_page.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../widgets/task_card.dart';

class AdminTaskListPage extends ConsumerStatefulWidget {
  const AdminTaskListPage({super.key});

  @override
  ConsumerState<AdminTaskListPage> createState() => _AdminTaskListPageState();
}

class _AdminTaskListPageState extends ConsumerState<AdminTaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabLabels = ["All", "To Do", "In Review", "Completed"];
  final List<String> statusFilter = [
    "all",
    "pending",
    "in_progress",
    "completed",
  ];

  final Map<String, IconData> tabIcons = {
    "All": Icons.list_alt,
    "To Do": Icons.pending_actions,
    "In Review": Icons.rate_review,
    "Completed": Icons.task_alt,
  };

  final Map<String, Color> tabColors = {
    "All": Colors.deepPurple,
    "To Do": Colors.orange,
    "In Review": Colors.blue,
    "Completed": Colors.green,
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     onPressed: () {
        //       // Search functionality placeholder
        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.filter_list),
        //     onPressed: () {
        //       // Filter functionality placeholder
        //     },
        //   ),
        // ],
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
                          text: label,
                          icon: Icon(tabIcons[label], size: 20),
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
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(tabIcons[category], color: tabColors[category], size: 20),
                const SizedBox(width: 8),
                Text(
                  "$category Tasks",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tabColors[category],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tabColors[category]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tabColors[category],
                    ),
                  ),
                ),
              ],
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

  Widget _buildEnhancedTaskCard(Task task) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TaskCard(task: task),
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
      default:
        return "No tasks found in this category.";
    }
  }
}
