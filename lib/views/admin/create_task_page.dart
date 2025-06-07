// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  const CreateTaskPage({super.key});

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final Set<String> selectedUsers = {};
  String selectedPriority = 'medium';
  DateTime? dueDate;

  final priorities = ['urgent', 'high', 'medium', 'low', 'easy'];

  // Map for priority colors
  final Map<String, Color> priorityColors = {
    'urgent': Colors.red.shade700,
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.green,
    'easy': Colors.blue,
  };

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: dueDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => dueDate = date);
    }
  }

  void _submitTask() async {
    // Check for required fields
    if (titleController.text.isEmpty ||
        selectedUsers.isEmpty ||
        dueDate == null) {
      // Show validation message with highlighted border
      setState(() {
        // This will trigger the border color to change in the build method
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Title, assignees, and due date are required',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        );
      },
    );

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.createTask(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        assignedTo: selectedUsers.toList(),
        priority: selectedPriority,
        dueDate: dueDate!,
      );
      ref.invalidate(taskServiceProvider);
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'Task created successfully',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Failed: $e',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _openUserSelector(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        );
      },
    );

    try {
      final users = await ref.read(userServiceProvider).getAllUsers();
      final tempSelected = Set<String>.from(selectedUsers);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (_) => StatefulBuilder(
              builder:
                  (context, setModalState) => Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Assignees",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        // Counter showing selected users
                        if (tempSelected.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${tempSelected.length} ${tempSelected.length == 1 ? 'user' : 'users'} selected",
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (tempSelected.isNotEmpty)
                                  TextButton.icon(
                                    icon: const Icon(Icons.clear_all, size: 16),
                                    label: const Text("Clear All"),
                                    onPressed: () {
                                      setModalState(() {
                                        tempSelected.clear();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child:
                              users.isEmpty
                                  ? const Center(
                                    child: Text(
                                      "No users found",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      final isChecked = tempSelected.contains(
                                        user.id,
                                      );
                                      return Card(
                                        elevation: 0,
                                        color:
                                            isChecked
                                                ? Colors.deepPurple.withOpacity(
                                                  0.1,
                                                )
                                                : Colors.grey.shade50,
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color:
                                                isChecked
                                                    ? Colors.deepPurple
                                                        .withOpacity(0.5)
                                                    : Colors.transparent,
                                            width: 1,
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          title: Text(
                                            user.username,
                                            style: TextStyle(
                                              fontWeight:
                                                  isChecked
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text(
                                            user.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          value: isChecked,
                                          activeColor: Colors.deepPurple,
                                          checkColor: Colors.white,
                                          secondary: CircleAvatar(
                                            backgroundColor:
                                                isChecked
                                                    ? Colors.deepPurple
                                                    : Colors.grey.shade200,
                                            foregroundColor: Colors.white,
                                            child: Text(
                                              user.username
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            setModalState(() {
                                              if (val == true) {
                                                tempSelected.add(user.id);
                                              } else {
                                                tempSelected.remove(user.id);
                                              }
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedUsers
                                ..clear()
                                ..addAll(tempSelected);
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text("Save Selection"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTitleEmpty = titleController.text.isEmpty;
    final bool isUsersEmpty = selectedUsers.isEmpty;
    final bool isDateEmpty = dueDate == null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Assign work to your team',
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
        actions: [
          // Help icon
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help tooltip
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fill in the form to create a new task'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form card
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title
                        _buildSectionHeader(
                          "Task Title",
                          Icons.title,
                          isRequired: true,
                          isError: isTitleEmpty,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: _inputDecoration(
                            "Enter task title",
                            isError: isTitleEmpty,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        _buildSectionHeader("Description", Icons.description),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            "Write something detailed about this task...",
                            alignLabelWithHint: true,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),

                        // Priority
                        _buildSectionHeader("Priority", Icons.flag_outlined),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: _inputDecoration("Select priority"),
                          items:
                              priorities.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: priorityColors[p],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        p.toUpperCase(),
                                        style: TextStyle(
                                          color: priorityColors[p],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              (val) => setState(() => selectedPriority = val!),
                          dropdownColor: Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: priorityColors[selectedPriority],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Due Date
                        _buildSectionHeader(
                          "Due Date",
                          Icons.calendar_today,
                          isRequired: true,
                          isError: isDateEmpty,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDueDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDateEmpty
                                        ? Colors.red
                                        : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color:
                                          dueDate == null
                                              ? Colors.grey
                                              : Colors.deepPurple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      dueDate == null
                                          ? 'Select due date'
                                          : DateFormat.yMMMd().format(dueDate!),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            dueDate == null
                                                ? Colors.grey.shade700
                                                : Colors.black,
                                        fontWeight:
                                            dueDate != null
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_calendar,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Assign To
                        _buildSectionHeader(
                          "Assign To",
                          Icons.people,
                          isRequired: true,
                          isError: isUsersEmpty,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _openUserSelector(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isUsersEmpty
                                        ? Colors.red
                                        : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color:
                                          selectedUsers.isEmpty
                                              ? Colors.grey
                                              : Colors.deepPurple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedUsers.isEmpty
                                          ? 'Select team members'
                                          : '${selectedUsers.length} ${selectedUsers.length == 1 ? 'user' : 'users'} selected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            selectedUsers.isEmpty
                                                ? Colors.grey.shade700
                                                : Colors.black,
                                        fontWeight:
                                            selectedUsers.isNotEmpty
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.group_add,
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding for submit button
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Submit button (floating at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _submitTask,
                icon: const Icon(Icons.add_task, size: 20),
                label: const Text(
                  'Create Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool isRequired = false,
    bool isError = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isError ? Colors.red : Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red : Colors.black87,
          ),
        ),
        if (isRequired)
          Text(
            " *",
            style: TextStyle(
              color: isError ? Colors.red : Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    bool isError = false,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade100,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.transparent,
          width: isError ? 1 : 0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isError ? Colors.red : Colors.deepPurple,
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
