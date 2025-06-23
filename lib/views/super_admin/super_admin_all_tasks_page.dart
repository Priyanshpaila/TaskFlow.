// ignore_for_file: deprecated_member_use, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/views/user/task_detail_page.dart';
import 'package:task_flow_app/views/widgets/task_card.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../state/auth_state.dart';

class SuperAdminAllTasksPage extends ConsumerStatefulWidget {
  const SuperAdminAllTasksPage({super.key});

  @override
  ConsumerState<SuperAdminAllTasksPage> createState() =>
      _SuperAdminAllTasksPageState();
}

class _SuperAdminAllTasksPageState extends ConsumerState<SuperAdminAllTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';

  final List<Map<String, dynamic>> taskStates = [
    {
      'status': 'all',
      'label': 'All',
      'icon': Icons.list_alt_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'status': 'pending',
      'label': 'Pending',
      'icon': Icons.schedule_rounded,
      'color': Color(0xFFEAB308),
    },
    {
      'status': 'in_progress',
      'label': 'In Progress',
      'icon': Icons.play_circle_outline_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'status': 'completed',
      'label': 'Completed',
      'icon': Icons.check_circle_outline_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'status': 'forward',
      'label': 'Forwarded',
      'icon': Icons.forward_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'status': 'abort',
      'label': 'Aborted',
      'icon': Icons.cancel_outlined,
      'color': Color(0xFFEF4444),
    },
    {
      'status': 'personal',
      'label': 'Personal',
      'icon': Icons.person_rounded,
      'color': Color(0xFFEC4899), // Pink
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: taskStates.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskService = ref.read(taskServiceProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'All Tasks',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon:
                        searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () => setState(() => searchQuery = ''),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF6366F1),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs:
                      taskStates.map((state) {
                        return Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(state['icon'], size: 16),
                                const SizedBox(width: 6),
                                Text(state['label']),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: auth.when(
        data: (user) {
          if (user == null) {
            return _buildErrorState('User not logged in');
          }

          return FutureBuilder<List<Task>>(
            future: taskService.fetchAllTasksForSuperAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState('Error: ${snapshot.error}');
              }

              final allTasks = snapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                children:
                    taskStates.map((state) {
                      final filteredTasks = _filterTasks(
                        allTasks,
                        state['status'],
                        searchQuery,
                      );
                      return _buildTaskList(filteredTasks, user, state);
                    }).toList(),
              );
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildErrorState('Auth error: $e'),
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks, String status, String query) {
    List<Task> filtered = tasks;

    if (status == 'personal') {
      // Frontend-only filter: personal task means createdBy == assignedTo (only one user)
      filtered =
          filtered
              .where(
                (task) =>
                    task.assignedTo.length == 1 &&
                    task.assignedTo.first == task.createdBy,
              )
              .toList();
    } else if (status != 'all') {
      // Normal backend status filtering (pending, completed, etc.)
      filtered = filtered.where((task) => task.status == status).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered =
          filtered
              .where(
                (task) =>
                    task.title.toLowerCase().contains(q) ||
                    (task.description ?? '').toLowerCase().contains(q),
              )
              .toList();
    }

    return filtered;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
          SizedBox(height: 24),
          Text(
            'Loading tasks...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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

  Widget _buildTaskList(
    List<Task> tasks,
    dynamic user,
    Map<String, dynamic> state,
  ) {
    if (tasks.isEmpty) {
      return _buildEmptyState(state);
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: const Color(0xFF6366F1),
      child: Column(
        children: [
          // Stats Header
          _buildStatsHeader(tasks, state),

          // Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TaskCard(
                    task: task,
                    isAdmin: false,
                    currentUserId: user.id,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailPage(task: task),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<Task> tasks, Map<String, dynamic> state) {
    final priorityStats = <String, int>{};
    for (final task in tasks) {
      priorityStats[task.priority] = (priorityStats[task.priority] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [state['color'], state['color'].withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: state['color'].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(state['icon'], color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${state['label']} Tasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (priorityStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    priorityStats.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _getPriorityIcon(entry.key),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key.toUpperCase()}: ${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Icon(Icons.warning_rounded, color: Colors.white, size: 16);
      case 'high':
        return const Icon(
          Icons.priority_high_rounded,
          color: Colors.white,
          size: 16,
        );
      case 'medium':
        return const Icon(Icons.remove_rounded, color: Colors.white, size: 16);
      case 'low':
        return const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 16,
        );
      case 'easy':
        return const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 16,
        );
      default:
        return const Icon(Icons.circle_outlined, color: Colors.white, size: 16);
    }
  }

  Widget _buildEmptyState(Map<String, dynamic> state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: state['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(state['icon'], size: 64, color: state['color']),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${state['label']} Tasks',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty
                  ? 'No tasks match your search criteria.'
                  : 'There are no ${state['label'].toLowerCase()} tasks at the moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => setState(() => searchQuery = ''),
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Search'),
                style: TextButton.styleFrom(
                  foregroundColor: state['color'],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
