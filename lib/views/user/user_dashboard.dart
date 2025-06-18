// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_flow_app/services/user_service.dart';
import '../../providers/task_provider.dart';
import '../../state/auth_state.dart';
import '../widgets/task_card.dart';
import 'task_detail_page.dart';

class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDrawerIndex = 0;

  String _selectedStatus = 'active'; // default or load from user model

  // Enhanced status options with better data structure
  final List<Map<String, dynamic>> _statusOptions = [
    {
      'value': 'active',
      'label': 'Active',
      'color': Colors.green,
      'icon': Icons.check_circle,
      'description': 'Available and ready to work',
    },
    {
      'value': 'inactive',
      'label': 'Inactive',
      'color': Colors.grey,
      'icon': Icons.radio_button_unchecked,
      'description': 'Not currently active',
    },
    {
      'value': 'dnd',
      'label': 'Do Not Disturb',
      'color': Colors.red,
      'icon': Icons.do_not_disturb,
      'description': 'Focused work mode',
    },
    {
      'value': 'away',
      'label': 'Away',
      'color': Colors.orange,
      'icon': Icons.schedule,
      'description': 'Temporarily unavailable',
    },
  ];

  final List<String> filters = [
    'All',
    'In Progress',
    'Pending',
    'High Priority',
    'History',
    'My Created',
    'Aborted',
  ];

  final Map<String, IconData> filterIcons = {
    'All': Icons.list_alt,
    'In Progress': Icons.pending_actions,
    'Pending': Icons.hourglass_empty,
    'High Priority': Icons.priority_high,
    'History': Icons.history,
    'My Created': Icons.person,
    'Aborted': Icons.cancel_outlined,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get current status data
  Map<String, dynamic> get _currentStatusData {
    return _statusOptions.firstWhere(
      (status) => status['value'] == _selectedStatus,
      orElse: () => _statusOptions[0],
    );
  }

  // Enhanced status dropdown widget
  Widget _buildStatusDropdown() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentStatusData['color'],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_currentStatusData['color'] as Color).withOpacity(
                        0.5,
                      ),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status icon
              Icon(
                _currentStatusData['icon'],
                size: 16,
                color: _currentStatusData['color'],
              ),
              const SizedBox(width: 4),
              // Dropdown arrow
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        itemBuilder:
            (context) =>
                _statusOptions.map((status) {
                  final isSelected = status['value'] == _selectedStatus;
                  return PopupMenuItem<String>(
                    value: status['value'],
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Status indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (status['color'] as Color).withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Icon(
                                status['icon'],
                                size: 18,
                                color: status['color'],
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 6,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Status info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status['label'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Colors.deepPurple
                                            : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status['description'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Selection indicator
                          if (isSelected)
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
        onSelected: (newStatus) async {
          if (newStatus != _selectedStatus) {
            // Show loading state
            setState(() {
              _selectedStatus = newStatus;
            });

            try {
              await UserService().updateUserStatus(newStatus);

              // Show success with enhanced snackbar
              if (mounted) {
                final statusData = _statusOptions.firstWhere(
                  (s) => s['value'] == newStatus,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(statusData['icon'], color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Status Updated',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'You are now ${statusData['label']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: statusData['color'],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              // Revert status on error
              setState(() {
                _selectedStatus = _statusOptions[0]['value']; // Reset to active
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Update Failed',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Could not update status: ${e.toString()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => _updateStatus(newStatus),
                    ),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  // Helper method for status update with retry capability
  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _selectedStatus = newStatus;
    });

    try {
      await UserService().updateUserStatus(newStatus);

      if (mounted) {
        final statusData = _statusOptions.firstWhere(
          (s) => s['value'] == newStatus,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(statusData['icon'], color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Status updated to ${statusData['label']}'),
              ],
            ),
            backgroundColor: statusData['color'],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List _applyFilter(List tasks, String filter) {
    if (filter == 'All') {
      return tasks.where((t) => t.status != 'completed').toList();
    }
    if (filter == 'History') {
      return tasks.where((t) => t.status == 'completed').toList();
    }
    if (filter == 'High Priority') {
      return tasks
          .where((t) => t.priority == 'urgent' || t.priority == 'high')
          .toList();
    }
    if (filter == 'My Created') {
      final user = ref.read(authStateProvider).value;
      return tasks.where((t) => t.createdBy == user?.id).toList();
    }

    if (filter == 'Aborted') {
      return tasks.where((t) => t.status == 'abort').toList();
    }
    return tasks
        .where((t) => t.status == filter.toLowerCase().replaceAll(' ', '_'))
        .toList();
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'High Priority':
        return Colors.red;
      case 'History':
        return Colors.green;
      case 'Aborted':
        return Colors.red.shade900;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final user = ref.watch(authStateProvider).value;
    final today = DateTime.now();
    final formatter = DateFormat('EEEE, MMMM d');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-personal-task');
        },
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text(
          'New Personal Task',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              formatter.format(today),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        // ✅ Enhanced status dropdown
        actions: [_buildStatusDropdown()],
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
              tabs:
                  filters
                      .map(
                        (f) => Tab(
                          child: Row(
                            children: [
                              Icon(filterIcons[f], size: 18),
                              const SizedBox(width: 8),
                              Text(f),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(user),
      body: tasksAsync.when(
        data: (tasks) {
          return TabBarView(
            controller: _tabController,
            children:
                filters.map((filter) {
                  final filtered = _applyFilter(tasks, filter);
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(taskListProvider),
                    color: Colors.deepPurple,
                    child:
                        filtered.isEmpty
                            ? _buildEmptyState(filter)
                            : _buildTaskList(filtered, filter),
                  );
                }).toList(),
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
        error: (e, _) => _errorRetry(e),
      ),
    );
  }

  // ✅ FIXED: Updated _buildTaskList method
  Widget _buildTaskList(List filtered, String filter) {
    final user = ref.read(authStateProvider).value!;
    final String currentUserId = user.id;
    final bool isAdmin = user.role == 'admin';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getFilterColor(filter).withOpacity(0.7),
                    _getFilterColor(filter),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getFilterColor(filter).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(filterIcons[filter], color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$filter Tasks",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${filtered.length} ${filtered.length == 1 ? 'task' : 'tasks'} to manage",
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
                      "${filtered.length}",
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
              final task = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TaskCard(
                  task: task,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  // ✅ FIXED: Pass onTap callback directly to TaskCard
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailPage(task: task),
                        ),
                      ),
                ),
              );
            }, childCount: filtered.length),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getFilterColor(filter).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  filterIcons[filter],
                  size: 80,
                  color: _getFilterColor(filter).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No $filter Tasks",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                filter == 'All'
                    ? "You don't have any active tasks."
                    : filter == 'History'
                    ? "You don't have any completed tasks yet."
                    : "You don't have any tasks in this category.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(user) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 32,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 5,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _currentStatusData['color'],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.username ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerTile(
            icon: Icons.dashboard_rounded,
            title: "Dashboard",
            index: 0,
          ),
          _buildDrawerTile(
            icon: Icons.person_outline,
            title: "My Profile",
            index: 1,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(authStateProvider.notifier).logout();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/auth',
                      (_) => false,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "LOGOUT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedDrawerIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:
              onTap ??
              () {
                setState(() {
                  _selectedDrawerIndex = index;
                });
                Navigator.pop(context);
              },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border:
                  isSelected
                      ? Border.all(
                        color: Colors.deepPurple.withOpacity(0.5),
                        width: 1,
                      )
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.deepPurple : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? Colors.deepPurple : Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorRetry(Object e) {
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
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              e.toString(),
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
}
