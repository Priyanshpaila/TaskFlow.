// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  final Task? editTask;

  const CreateTaskPage({super.key, this.editTask});

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final Set<String> selectedUsers = {};
  String selectedPriority = 'medium';
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final priorities = ['urgent', 'high', 'medium', 'low', 'easy'];

  final Map<String, Map<String, dynamic>> priorityData = {
    'urgent': {
      'color': Colors.red.shade700,
      'icon': Icons.warning_rounded,
      'description': 'Needs immediate attention',
    },
    'high': {
      'color': Colors.red,
      'icon': Icons.priority_high,
      'description': 'Important and time-sensitive',
    },
    'medium': {
      'color': Colors.orange,
      'icon': Icons.remove,
      'description': 'Standard priority level',
    },
    'low': {
      'color': Colors.green,
      'icon': Icons.trending_down,
      'description': 'Can be done when time permits',
    },
    'easy': {
      'color': Colors.blue,
      'icon': Icons.sentiment_satisfied,
      'description': 'Simple task, quick completion',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    if (widget.editTask != null) {
      final task = widget.editTask!;
      titleController.text = task.title;
      descriptionController.text = task.description ?? '';
      selectedPriority = task.priority;
      dueDate = task.dueDate;
      if (dueDate != null) {
        dueTime = TimeOfDay.fromDateTime(dueDate!);
      }
      selectedUsers.addAll(task.assignedTo);
      isEditing = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: dueDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: dueTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.deepPurple,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      setState(() {
        dueDate = date;
        if (time != null) {
          dueTime = time;
          dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }

  void _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      _showValidationError();
      return;
    }

    if (selectedUsers.isEmpty || dueDate == null) {
      _showValidationError();
      return;
    }

    _showLoadingDialog();

    try {
      final taskService = ref.read(taskServiceProvider);

      if (isEditing && widget.editTask != null) {
        await taskService.editTask(
          taskId: widget.editTask!.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          assignedTo: selectedUsers.toList(),
          priority: selectedPriority,
          dueDate: dueDate!,
        );
      } else {
        await taskService.createTask(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          assignedTo: selectedUsers.toList(),
          priority: selectedPriority,
          dueDate: dueDate!,
        );
      }

      ref.invalidate(taskServiceProvider);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar(
          isEditing ? 'Failed to update task: $e' : 'Failed to create task: $e',
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEditing ? 'Updating task...' : 'Creating task...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing
                      ? 'Task Updated Successfully!'
                      : 'Task Created Successfully!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The task has been ${isEditing ? 'updated' : 'assigned to ${selectedUsers.length} team member${selectedUsers.length > 1 ? 's' : ''}'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return
                },
                child: const Text('Done'),
              ),
              if (!isEditing)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Another'),
                ),
            ],
          ),
    );
  }

  void _resetForm() {
    setState(() {
      titleController.clear();
      descriptionController.clear();
      selectedUsers.clear();
      selectedPriority = 'medium';
      dueDate = null;
      dueTime = null;
    });
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Please fill in all required fields',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openUserSelector(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog();

    try {
      final users = await ref.read(userServiceProvider).getAllUsers();
      final tempSelected = Set<String>.from(selectedUsers);

      if (mounted) Navigator.pop(context); // Close loading

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildUserSelectorSheet(users, tempSelected),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showErrorSnackBar('Failed to load users: $e');
      }
    }
  }

  Widget _buildUserSelectorSheet(List users, Set<String> tempSelected) {
    return StatefulBuilder(
      builder:
          (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        "Select Team Members",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Selection counter and actions
                if (tempSelected.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.deepPurple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "${tempSelected.length} selected",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text("Clear All"),
                          onPressed: () {
                            setModalState(() => tempSelected.clear());
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 1),

                // User list
                Expanded(
                  child:
                      users.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No users found",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final isSelected = tempSelected.contains(user.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.deepPurple.withOpacity(0.1)
                                          : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.deepPurple
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            isSelected
                                                ? Colors.deepPurple
                                                : Colors.grey.shade300,
                                        foregroundColor: Colors.white,
                                        radius: 24,
                                        child: Text(
                                          user.username
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    user.username,
                                    style: TextStyle(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          user.role.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    activeColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
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
                                  ),
                                  onTap: () {
                                    setModalState(() {
                                      if (isSelected) {
                                        tempSelected.remove(user.id);
                                      } else {
                                        tempSelected.add(user.id);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                ),

                // Save button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedUsers
                          ..clear()
                          ..addAll(tempSelected);
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(
                      tempSelected.isEmpty
                          ? "Save Selection"
                          : "Save ${tempSelected.length} Member${tempSelected.length > 1 ? 's' : ''}",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Task' : 'Create New Task',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text('How to Create a Task'),
                        ],
                      ),
                      content: const Text(
                        '1. Enter a clear task title\n'
                        '2. Add detailed description\n'
                        '3. Set priority level\n'
                        '4. Choose due date & time\n'
                        '5. Assign to team members\n'
                        '6. Click Create Task',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTaskTitleSection(),
                        const SizedBox(height: 24),
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),
                        _buildPrioritySection(),
                        const SizedBox(height: 24),
                        _buildDueDateSection(),
                        const SizedBox(height: 24),
                        _buildAssigneeSection(),
                        const SizedBox(
                          height: 100,
                        ), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: _submitTask,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_task),
          label: Text(
            isEditing ? 'Update Task' : 'Create Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTaskTitleSection() {
    return _buildSection(
      title: 'Task Title',
      icon: Icons.title,
      isRequired: true,
      child: TextFormField(
        controller: titleController,
        decoration: _inputDecoration('Enter a clear, descriptive title'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Task title is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildSection(
      title: 'Description',
      icon: Icons.description,
      child: TextFormField(
        controller: descriptionController,
        maxLines: 4,
        decoration: _inputDecoration(
          'Provide detailed information about this task...',
          alignLabelWithHint: true,
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return _buildSection(
      title: 'Priority Level',
      icon: Icons.flag_outlined,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children:
              priorities.map((priority) {
                final data = priorityData[priority]!;
                final isSelected = selectedPriority == priority;

                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? data['color'].withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? data['color'] : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(data['icon'], color: data['color'], size: 20),
                    ),
                    title: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: data['color'],
                      ),
                    ),
                    subtitle: Text(
                      data['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Radio<String>(
                      value: priority,
                      groupValue: selectedPriority,
                      activeColor: data['color'],
                      onChanged: (value) {
                        setState(() => selectedPriority = value!);
                      },
                    ),
                    onTap: () {
                      setState(() => selectedPriority = priority);
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDueDateSection() {
    return _buildSection(
      title: 'Due Date & Time',
      icon: Icons.schedule,
      isRequired: true,
      child: GestureDetector(
        onTap: _pickDueDate,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event, color: Colors.deepPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dueDate == null ? 'Select due date' : 'Due Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dueDate == null
                          ? 'Tap to choose date and time'
                          : DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(dueDate!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            dueDate == null
                                ? Colors.grey.shade500
                                : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeSection() {
    return _buildSection(
      title: 'Assign To',
      icon: Icons.people,
      isRequired: true,
      child: GestureDetector(
        onTap: () => _openUserSelector(context, ref),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group_add,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedUsers.isEmpty
                          ? 'Select team members'
                          : 'Assigned To',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedUsers.isEmpty
                          ? 'Tap to choose assignees'
                          : '${selectedUsers.length} member${selectedUsers.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            selectedUsers.isEmpty
                                ? Colors.grey.shade500
                                : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
