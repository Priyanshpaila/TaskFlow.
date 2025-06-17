// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_flow_app/providers/task_provider.dart';
import '../../models/task_model.dart';

class CreatePersonalTaskPage extends ConsumerStatefulWidget {
  final Task? editTask;

  const CreatePersonalTaskPage({super.key, this.editTask});

  @override
  ConsumerState<CreatePersonalTaskPage> createState() =>
      _CreatePersonalTaskPageState();
}

class _CreatePersonalTaskPageState extends ConsumerState<CreatePersonalTaskPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedPriority = 'medium';
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isLoading = false;
  bool isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final priorities = [
    {
      'value': 'urgent',
      'label': 'Urgent',
      'color': Colors.red,
      'icon': Icons.warning,
    },
    {
      'value': 'high',
      'label': 'High',
      'color': Colors.orange,
      'icon': Icons.priority_high,
    },
    {
      'value': 'medium',
      'label': 'Medium',
      'color': Colors.blue,
      'icon': Icons.remove,
    },
    {
      'value': 'low',
      'label': 'Low',
      'color': Colors.green,
      'icon': Icons.low_priority,
    },
    {
      'value': 'easy',
      'label': 'Easy',
      'color': Colors.teal,
      'icon': Icons.check_circle_outline,
    },
  ];

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
    _animationController.forward();

    if (widget.editTask != null) {
      isEditing = true;
      final task = widget.editTask!;
      titleController.text = task.title;
      descriptionController.text = task.description ?? '';
      selectedPriority = task.priority;
      dueDate = task.dueDate;
      if (dueDate != null) {
        dueTime = TimeOfDay.fromDateTime(dueDate!);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    _animationController.dispose();
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.deepPurple),
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
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: Colors.deepPurple),
            ),
            child: child!,
          );
        },
      );

      setState(() {
        dueTime = time;
        dueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 0,
          time?.minute ?? 0,
        );
      });
    }
  }

  void _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    if (dueDate == null) {
      _showSnackBar('Please select a due date', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final taskService = ref.read(taskServiceProvider);

      if (isEditing && widget.editTask != null) {
        await taskService.editTask(
          taskId: widget.editTask!.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: selectedPriority,
          dueDate: dueDate!,
        );
      } else {
        await taskService.createPersonalTask(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: selectedPriority,
          dueDate: dueDate!,
        );
      }

      if (mounted) {
        setState(() => isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar(
          '${isEditing ? 'Update' : 'Creation'} failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(isEditing ? "Task Updated" : "Success!"),
              ],
            ),
            content: Text(
              isEditing
                  ? "Your personal task has been updated successfully."
                  : "Your personal task has been created successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context); // Pop page
                  ref.invalidate(taskServiceProvider);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Task' : 'Create Your Task',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('Task Details'),
              const SizedBox(height: 16),
              _buildTaskTitleInput(),
              const SizedBox(height: 20),
              _buildTaskDescriptionInput(),
              const SizedBox(height: 32),
              _buildSectionHeader('Priority & Schedule'),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 20),
              _buildDueDateSelector(),
              const SizedBox(height: 40),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTaskTitleInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: titleController,
        decoration: InputDecoration(
          labelText: 'Task Title *',
          hintText: 'Enter your task title',
          prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator:
            (val) =>
                val == null || val.trim().isEmpty
                    ? 'Task title is required'
                    : null,
      ),
    );
  }

  Widget _buildTaskDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Description',
          hintText: 'Add task description (optional)',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Icon(Icons.description, color: Colors.deepPurple),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                priorities.map((priority) {
                  final isSelected = selectedPriority == priority['value'];
                  return GestureDetector(
                    onTap:
                        () => setState(
                          () => selectedPriority = priority['value'] as String,
                        ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (priority['color'] as Color).withOpacity(0.1)
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isSelected
                                  ? (priority['color'] as Color)
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            priority['icon'] as IconData,
                            size: 16,
                            color:
                                isSelected
                                    ? (priority['color'] as Color)
                                    : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            priority['label'] as String,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? (priority['color'] as Color)
                                      : Colors.grey.shade700,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: _pickDueDate,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event, color: Colors.deepPurple),
        ),
        title: Text(
          dueDate == null ? "Select Due Date & Time" : "Due Date & Time",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle:
            dueDate != null
                ? Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(dueDate!),
                  style: TextStyle(color: Colors.grey.shade600),
                )
                : const Text('Tap to select date and time'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      isEditing ? 'Update Task' : 'Create Task',
                      style: TextStyle(
                        color: Colors.white,
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
