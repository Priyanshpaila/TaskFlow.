// ignore_for_file: deprecated_member_use, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_flow_app/views/admin/create_task_page.dart';
import 'package:task_flow_app/views/allUsers/self_task_create.dart';
import '../../models/task_model.dart';

// Enhanced chip types
enum ChipType { priority, status, date, assignee }

class TaskCard extends StatefulWidget {
  final Task task;
  final bool showBadgesInside;
  final String currentUserId;
  final bool isAdmin;
  final VoidCallback? onTap; // Add onTap callback

  const TaskCard({
    super.key,
    required this.task,
    this.showBadgesInside = true,
    required this.currentUserId,
    required this.isAdmin,
    this.onTap, // Add onTap parameter
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    // Call the onTap callback when tap is completed
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        widget.task.dueDate != null
            ? DateFormat('MMM d, yyyy').format(widget.task.dueDate!)
            : null;

    final bool isOverdue =
        widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        widget.task.status != 'completed';

    final bool isCompleted = widget.task.status == 'completed';
    final bool isHighPriority =
        widget.task.priority == 'high' || widget.task.priority == 'urgent';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        _isPressed
                            ? Colors.black.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: Offset(0, _isPressed ? 6 : 3),
                    spreadRadius: _isPressed ? 1 : 0,
                  ),
                ],
                border: Border.all(
                  color:
                      isOverdue
                          ? Colors.red.withOpacity(0.3)
                          : isHighPriority && !isCompleted
                          ? _getPriorityColor(
                            widget.task.priority,
                          ).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  width: isOverdue ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Gradient background for high priority tasks
                    if (isHighPriority && !isCompleted)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getPriorityColor(
                                  widget.task.priority,
                                ).withOpacity(0.03),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                    // Status indicator bar
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color:
                              isOverdue
                                  ? Colors.red
                                  : _getStatusColor(widget.task.status),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with title and actions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status checkbox
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 2,
                                  right: 12,
                                ),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isCompleted
                                          ? _getStatusColor(widget.task.status)
                                          : Colors.transparent,
                                  border:
                                      isCompleted
                                          ? null
                                          : Border.all(
                                            color: _getStatusColor(
                                              widget.task.status,
                                            ),
                                            width: 2.5,
                                          ),
                                  boxShadow:
                                      isCompleted
                                          ? [
                                            BoxShadow(
                                              color: _getStatusColor(
                                                widget.task.status,
                                              ).withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    isCompleted
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),

                              // Title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.task.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                            isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                        decorationColor: Colors.grey.shade500,
                                        decorationThickness: 2,
                                        color:
                                            isCompleted
                                                ? Colors.grey.shade500
                                                : Colors.black87,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Description
                                    if (widget.task.description != null &&
                                        widget.task.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          widget.task.description!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isCompleted
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (widget.task.createdBy != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Created by: ${widget.task.createdByUsername ?? widget.task.createdBy}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Edit button - Prevent tap propagation
                              if ((widget.task.createdBy ==
                                          widget.currentUserId ||
                                      widget.isAdmin) &&
                                  widget.task.status != 'completed' &&
                                  widget.task.status != 'abort')
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // Prevent the card tap from firing
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    widget.isAdmin
                                                        ? CreateTaskPage(
                                                          editTask: widget.task,
                                                        )
                                                        : CreatePersonalTaskPage(
                                                          editTask: widget.task,
                                                        ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Badges and info
                          if (widget.showBadgesInside)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildModernChip(
                                  text: _formatPriority(widget.task.priority),
                                  icon: _getPriorityIcon(widget.task.priority),
                                  color: _getPriorityColor(
                                    widget.task.priority,
                                  ),
                                  type: ChipType.priority,
                                ),
                                _buildModernChip(
                                  text: _formatStatus(widget.task.status),
                                  icon: _getStatusIcon(widget.task.status),
                                  color: _getStatusColor(widget.task.status),
                                  type: ChipType.status,
                                ),
                                if (formattedDate != null)
                                  _buildModernChip(
                                    text: formattedDate,
                                    icon:
                                        isOverdue
                                            ? Icons.warning_amber_rounded
                                            : Icons.schedule_outlined,
                                    color: isOverdue ? Colors.red : Colors.blue,
                                    type: ChipType.date,
                                    isOverdue: isOverdue,
                                  ),
                                if (widget.task.assignedTo.isNotEmpty)
                                  _buildModernChip(
                                    text:
                                        "${widget.task.assignedTo.length} assigned",
                                    icon: Icons.people_outline,
                                    color: Colors.deepPurple,
                                    type: ChipType.assignee,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Overdue banner
                    if (isOverdue)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "OVERDUE",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
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
          ),
        );
      },
    );
  }

  Widget _buildModernChip({
    required String text,
    required IconData icon,
    required Color color,
    required ChipType type,
    bool isOverdue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isOverdue ? 0.6 : 0.2),
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced color schemes
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade600;
      case 'in_progress':
        return Colors.blue.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'abort':
        return Colors.red.shade900;
      case 'forward':
        return Colors.purple;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.pending_actions;
      case 'pending':
        return Icons.hourglass_empty;
      case 'abort':
        return Icons.cancel_outlined;
      case 'forward':
        return Icons.forward;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      case 'easy':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'easy':
        return Icons.check_circle_outline;
      default:
        return Icons.flag_outlined;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatPriority(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
  }
}
