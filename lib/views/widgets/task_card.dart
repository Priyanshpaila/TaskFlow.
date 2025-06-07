// ignore_for_file: unnecessary_null_comparison, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool showBadgesInside;

  const TaskCard({super.key, required this.task, this.showBadgesInside = true});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        task.dueDate != null
            ? DateFormat('MMM d, yyyy').format(task.dueDate!)
            : null;

    final bool isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'completed';

    final bool isCompleted = task.status == 'completed';
    final bool isHighPriority =
        task.priority == 'high' || task.priority == 'urgent';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color:
                  isOverdue
                      ? Colors.red.withOpacity(0.3)
                      : isHighPriority && !isCompleted
                      ? _getPriorityColor(task.priority).withOpacity(0.3)
                      : Colors.transparent,
              width: isOverdue || (isHighPriority && !isCompleted) ? 1.5 : 0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Status indicator bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    color:
                        isOverdue ? Colors.red : _getStatusColor(task.status),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left padding to account for status bar
                      const SizedBox(width: 6),

                      // Content column
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row with completion status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Task completion indicator
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 3,
                                    right: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        isCompleted
                                            ? null
                                            : Border.all(
                                              color: _getStatusColor(
                                                task.status,
                                              ),
                                              width: 2,
                                            ),
                                    color:
                                        isCompleted
                                            ? _getStatusColor(task.status)
                                            : Colors.transparent,
                                  ),
                                  width: 18,
                                  height: 18,
                                  child:
                                      isCompleted
                                          ? const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),

                                // Title
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                      color:
                                          isCompleted
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Description if available
                            if (task.description != null &&
                                task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 28,
                                  top: 6,
                                  bottom: 8,
                                ),
                                child: Text(
                                  task.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Metadata chips
                            if (showBadgesInside)
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Priority chip
                                    _buildEnhancedChip(
                                      text: _formatPriority(task.priority),
                                      icon: _getPriorityIcon(task.priority),
                                      color: _getPriorityColor(task.priority),
                                    ),

                                    // Status chip
                                    _buildEnhancedChip(
                                      text: _formatStatus(task.status),
                                      icon: _getStatusIcon(task.status),
                                      color: _getStatusColor(task.status),
                                    ),

                                    // Due date chip
                                    if (formattedDate != null)
                                      _buildEnhancedChip(
                                        text: formattedDate,
                                        icon:
                                            isOverdue
                                                ? Icons.warning_amber_rounded
                                                : Icons.event,
                                        color:
                                            isOverdue
                                                ? Colors.red
                                                : Colors.blue,
                                        isOverdue: isOverdue,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Assignee indicator (if available)
                if (task.assignedTo != null && task.assignedTo.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${task.assignedTo.length}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Overdue indicator
                if (isOverdue)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "OVERDUE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.pending_actions;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      case 'easy':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      case 'easy':
        return Icons.check;
      default:
        return Icons.flag;
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

  Widget _buildEnhancedChip({
    required String text,
    required IconData icon,
    required Color color,
    bool isOverdue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            isOverdue
                ? Border.all(color: color.withOpacity(0.5), width: 1)
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
