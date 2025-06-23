// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';

class SuperAdminCreateTaskPage extends ConsumerStatefulWidget {
  const SuperAdminCreateTaskPage({super.key});

  @override
  ConsumerState<SuperAdminCreateTaskPage> createState() =>
      _SuperAdminCreateTaskPageState();
}

class _SuperAdminCreateTaskPageState
    extends ConsumerState<SuperAdminCreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? dueDate;
  String selectedPriority = 'medium';
  final Set<String> selectedUserIds = {};
  List<User> allUsers = [];

  bool isSubmitting = false;

  final List<Map<String, dynamic>> priorities = [
    {
      'value': 'urgent',
      'label': 'URGENT',
      'color': Color(0xFFDC2626),
      'icon': Icons.warning_rounded,
    },
    {
      'value': 'high',
      'label': 'HIGH',
      'color': Color(0xFFEA580C),
      'icon': Icons.priority_high_rounded,
    },
    {
      'value': 'medium',
      'label': 'MEDIUM',
      'color': Color(0xFFD97706),
      'icon': Icons.remove_rounded,
    },
    {
      'value': 'low',
      'label': 'LOW',
      'color': Color(0xFF059669),
      'icon': Icons.keyboard_arrow_down_rounded,
    },
    {
      'value': 'easy',
      'label': 'EASY',
      'color': Color(0xFF0891B2),
      'icon': Icons.check_circle_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ref.read(userServiceProvider).getAllUsersSuperAdmin();
      setState(() => allUsers = users);
    } catch (e) {
      // Handle error silently, will be shown in bottom sheet
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    if (dueDate == null) {
      _showErrorSnackBar('Please select a due date');
      return;
    }

    if (selectedUserIds.isEmpty) {
      _showErrorSnackBar('Please assign the task to at least one user');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ref
          .read(taskServiceProvider)
          .createTaskAsSuperAdmin(
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            priority: selectedPriority,
            dueDate: dueDate!,
            assignedTo: selectedUserIds.toList(),
          );

      if (mounted) {
        _showSuccessSnackBar('Task created successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create task: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showUserAssignmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => UserAssignmentBottomSheet(
            allUsers: allUsers,
            selectedUserIds: selectedUserIds,
            onUsersSelected: (userIds) {
              setState(() {
                selectedUserIds.clear();
                selectedUserIds.addAll(userIds);
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Create New Task',
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Details Section
              _buildSectionCard(
                title: 'Task Details',
                icon: Icons.assignment_outlined,
                children: [
                  _buildTextField(
                    controller: titleController,
                    label: 'Task Title',
                    hint: 'Enter a descriptive task title',
                    icon: Icons.title_rounded,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Task title is required'
                                : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'Provide detailed task description',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Priority & Due Date Section
              _buildSectionCard(
                title: 'Priority & Timeline',
                icon: Icons.schedule_rounded,
                children: [
                  _buildPrioritySelector(),
                  const SizedBox(height: 20),
                  _buildDateSelector(),
                ],
              ),

              const SizedBox(height: 24),

              // User Assignment Section
              _buildUserAssignmentCard(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
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
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                priorities.map((priority) {
                  final isSelected = selectedPriority == priority['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap:
                          () => setState(
                            () => selectedPriority = priority['value'],
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? priority['color'] : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? priority['color']
                                    : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              priority['icon'],
                              size: 18,
                              color:
                                  isSelected ? Colors.white : priority['color'],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priority['label'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : priority['color'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6366F1),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => dueDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate != null
                        ? DateFormat('EEEE, MMM dd, yyyy').format(dueDate!)
                        : 'Select due date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          dueDate != null
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAssignmentCard() {
    return _buildSectionCard(
      title: 'Assign Users',
      icon: Icons.people_outline_rounded,
      children: [
        GestureDetector(
          onTap: _showUserAssignmentBottomSheet,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Users',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedUserIds.isNotEmpty
                            ? '${selectedUserIds.length} user${selectedUserIds.length == 1 ? '' : 's'} selected'
                            : 'Tap to select users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              selectedUserIds.isNotEmpty
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        if (selectedUserIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSelectedUsersPreview(),
        ],
      ],
    );
  }

  Widget _buildSelectedUsersPreview() {
    final selectedUsers =
        allUsers.where((user) => selectedUserIds.contains(user.id)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6366F1),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Users (${selectedUsers.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedUsers.take(3).map((user) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(
                            0xFF6366F1,
                          ).withOpacity(0.1),
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          if (selectedUsers.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              '+${selectedUsers.length - 3} more users',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
        ),
        child:
            isSubmitting
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Creating Task...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task_rounded, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Bottom Sheet Widget for User Assignment
class UserAssignmentBottomSheet extends StatefulWidget {
  final List<User> allUsers;
  final Set<String> selectedUserIds;
  final Function(Set<String>) onUsersSelected;

  const UserAssignmentBottomSheet({
    super.key,
    required this.allUsers,
    required this.selectedUserIds,
    required this.onUsersSelected,
  });

  @override
  State<UserAssignmentBottomSheet> createState() =>
      _UserAssignmentBottomSheetState();
}

class _UserAssignmentBottomSheetState extends State<UserAssignmentBottomSheet> {
  String? roleFilter;
  String? divisionFilter;
  String searchQuery = '';
  late Set<String> tempSelectedUserIds;

  @override
  void initState() {
    super.initState();
    tempSelectedUserIds = Set.from(widget.selectedUserIds);
  }

  List<User> get filteredUsers {
    return widget.allUsers.where((user) {
      final matchesRole = roleFilter == null || user.role == roleFilter;
      final matchesDivision =
          divisionFilter == null || user.division == divisionFilter;
      final matchesSearch = user.username.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchesRole && matchesDivision && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.allUsers.map((u) => u.role).toSet().toList()..sort();
    final divisions =
        widget.allUsers.map((u) => u.division).toSet().toList()..sort();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assign Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onUsersSelected(tempSelectedUserIds);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search users by name...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
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

                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Roles',
                        isSelected: roleFilter == null,
                        onTap: () => setState(() => roleFilter = null),
                      ),
                      ...roles.map(
                        (role) => _buildFilterChip(
                          label: role.toUpperCase(),
                          isSelected: roleFilter == role,
                          onTap: () => setState(() => roleFilter = role),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Divisions',
                        isSelected: divisionFilter == null,
                        onTap: () => setState(() => divisionFilter = null),
                      ),
                      ...divisions.map(
                        (division) => _buildFilterChip(
                          label: division,
                          isSelected: divisionFilter == division,
                          onTap:
                              () => setState(() => divisionFilter = division),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected Count
          if (tempSelectedUserIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tempSelectedUserIds.length} user${tempSelectedUserIds.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        () => setState(() => tempSelectedUserIds.clear()),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Users List
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (widget.allUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No Users Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no users to assign tasks to.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'No Users Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final isSelected = tempSelectedUserIds.contains(user.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  tempSelectedUserIds.remove(user.id);
                } else {
                  tempSelectedUserIds.add(user.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.white,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isSelected
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6366F1).withOpacity(0.1),
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF6366F1),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.role.toUpperCase()} • ${user.division}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
