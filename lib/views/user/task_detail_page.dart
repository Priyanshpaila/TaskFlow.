// ignore_for_file: unused_result, curly_braces_in_flow_control_structures, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/comment_provider.dart';
import '../../providers/task_provider.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final Task task;
  const TaskDetailPage({super.key, required this.task});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final commentController = TextEditingController();

  void _submitComment() async {
    if (commentController.text.trim().isEmpty) return;
    final commentService = ref.read(commentServiceProvider);
    await commentService.addComment(
      widget.task.id,
      commentController.text.trim(),
    );
    commentController.clear();
    ref.refresh(commentListProvider(widget.task.id));
    ref.invalidate(commentServiceProvider);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'forward':
        return const Color(0xFF9C27B0);
      case 'abort':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  // Check if current status is terminal (cannot be changed)
  bool _isTerminalStatus(String status) {
    return status == 'completed' || status == 'abort';
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentListProvider(widget.task.id));
    final taskService = ref.read(taskServiceProvider);
    final statuses = [
      'pending',
      'in_progress',
      'completed',
      'forward',
      'abort',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Task Details",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Task Header Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey.shade50],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with gradient accent
                        Container(
                          padding: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description with enhanced styling
                        if (widget.task.description != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.05),
                                  const Color(0xFF8B5CF6).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.task.description!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF475569),
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (widget.task.status == 'forward' ||
                            widget.task.status == 'abort')
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.task.reason ?? "No reason provided.",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 28),

                        // Enhanced metadata chips
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _enhancedChip(
                              Icons.flag_outlined,
                              "Priority: ${widget.task.priority.toUpperCase()}",
                              _getPriorityColor(widget.task.priority),
                            ),
                            _enhancedDropdownChip(
                              icon: Icons.track_changes_outlined,
                              value: widget.task.status,
                              options: statuses,
                              color: _getStatusColor(widget.task.status),
                              onChanged: (statusWithReason) async {
                                if (statusWithReason == null) return;

                                final parts = statusWithReason.split('||');
                                final newStatus = parts[0];
                                final reason =
                                    parts.length > 1 ? parts[1] : null;

                                try {
                                  await taskService.updateTaskStatus(
                                    taskId: widget.task.id,
                                    newStatus: newStatus,
                                    reason: reason,
                                  );
                                  ref.refresh(
                                    commentListProvider(widget.task.id),
                                  );
                                  ref.invalidate(taskServiceProvider);

                                  if (!mounted) return;

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Status updated to ${_formatStatus(newStatus)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  // Pop context after successful status update
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text('Failed to update: $e'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                              formatLabel: _formatStatus,
                            ),
                            _enhancedChip(
                              Icons.schedule_outlined,
                              "Due: ${DateFormat.yMMMd().format(widget.task.dueDate ?? DateTime.now())}",
                              const Color(0xFF06B6D4),
                            ),
                          ],
                        ),

                        // Terminal status indicator
                        if (_isTerminalStatus(widget.task.status))
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                widget.task.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(
                                  widget.task.status,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.task.status == 'completed'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _getStatusColor(widget.task.status),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.task.status == 'completed'
                                        ? 'This task has been completed and cannot be modified.'
                                        : 'This task has been aborted and cannot be modified.',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        widget.task.status,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Enhanced Comments Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comments header with gradient
                        Container(
                          padding: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.forum_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "Comments",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              comments.maybeWhen(
                                data:
                                    (list) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "${list.length} ${list.length == 1 ? 'comment' : 'comments'}",
                                        style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                orElse: () => const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        comments.when(
                          data:
                              (list) =>
                                  list.isEmpty
                                      ? _buildEmptyCommentsState()
                                      : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: list.length,
                                        separatorBuilder:
                                            (_, __) => Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.grey.withOpacity(
                                                      0.3,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                        itemBuilder: (_, i) {
                                          final c = list[i];
                                          final localTime =
                                              c.createdAt.toLocal();
                                          return _buildCommentItem(
                                            c,
                                            localTime,
                                          );
                                        },
                                      ),
                          loading: () => _buildLoadingState(),
                          error: (e, _) => _buildErrorState(e),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Only show comment input if task is not in terminal state
          if (!_isTerminalStatus(widget.task.status))
            // Enhanced comment input bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16,
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF8B5CF6),
                              size: 20,
                            ),
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitComment,
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "No comments yet",
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Be the first to add a comment",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Error loading comments",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment, DateTime localTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                comment.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${DateFormat('MMM d').format(localTime)} at ${DateFormat('h:mm a').format(localTime)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _enhancedChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedDropdownChip({
    required IconData icon,
    required String value,
    required List<String> options,
    required Color color,
    required ValueChanged<String?> onChanged,
    String Function(String)? formatLabel,
  }) {
    // If current status is terminal, don't show dropdown
    if (_isTerminalStatus(value)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              formatLabel != null ? formatLabel(value) : value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lock, size: 14, color: color.withOpacity(0.7)),
          ],
        ),
      );
    }

    final statusOrder = [
      'pending',
      'in_progress',
      'forward',
      'completed',
      'abort',
    ];
    final currentIndex = statusOrder.indexOf(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down, color: color, size: 18),
              isDense: true,
              items:
                  options.map((s) {
                    final optionIndex = statusOrder.indexOf(s);
                    final isDisabled =
                        optionIndex < currentIndex &&
                        s != 'forward' &&
                        s != 'abort';

                    return DropdownMenuItem<String>(
                      value: isDisabled ? null : s,
                      enabled: !isDisabled,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          formatLabel != null ? formatLabel(s) : s,
                          style: TextStyle(
                            color: isDisabled ? Colors.grey : color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (selected) async {
                if (selected == null || selected == value) return;

                if (selected == 'forward' || selected == 'abort') {
                  final reason = await _showEnhancedReasonDialog(
                    context,
                    selected,
                  );
                  if (reason == null || reason.trim().isEmpty) return;
                  onChanged('$selected||$reason');
                } else {
                  onChanged(selected);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showEnhancedReasonDialog(
    BuildContext context,
    String status,
  ) {
    final controller = TextEditingController();
    final title = status == 'forward' ? 'Forward Task' : 'Abort Task';
    final color =
        status == 'forward' ? const Color(0xFF9C27B0) : const Color(0xFFEF4444);
    final icon = status == 'forward' ? Icons.forward : Icons.cancel;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, color.withOpacity(0.02)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please provide a reason for this action',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: controller,
                            maxLines: 4,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter reason for ${status == 'forward' ? 'forwarding' : 'aborting'} this task...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pop(context, controller.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              status == 'forward' ? 'Forward' : 'Abort',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
