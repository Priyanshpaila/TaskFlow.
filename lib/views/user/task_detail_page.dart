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
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentListProvider(widget.task.id));
    final taskService = ref.read(taskServiceProvider);
    final statuses = ['pending', 'in_progress', 'completed'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.more_vert),
        //     onPressed: () {
        //       // Task options menu
        //       showModalBottomSheet(
        //         context: context,
        //         builder:
        //             (context) => Column(
        //               mainAxisSize: MainAxisSize.min,
        //               children: [
        //                 ListTile(
        //                   leading: const Icon(Icons.edit),
        //                   title: const Text('Edit Task'),
        //                   onTap: () {
        //                     Navigator.pop(context);
        //                     // Edit task implementation
        //                   },
        //                 ),
        //                 ListTile(
        //                   leading: const Icon(Icons.delete, color: Colors.red),
        //                   title: const Text(
        //                     'Delete Task',
        //                     style: TextStyle(color: Colors.red),
        //                   ),
        //                   onTap: () {
        //                     Navigator.pop(context);
        //                     // Delete task implementation
        //                   },
        //                 ),
        //               ],
        //             ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Task Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Description
                        Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.task.description != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.task.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Metadata chips
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _chip(
                              Icons.flag_outlined,
                              "Priority: ${widget.task.priority.toUpperCase()}",
                              _getPriorityColor(widget.task.priority),
                            ),
                            _dropdownChip(
                              icon: Icons.check_circle_outline,
                              value: widget.task.status,
                              options: statuses,
                              color: _getStatusColor(widget.task.status),
                              onChanged: (newStatus) async {
                                if (newStatus == null ||
                                    newStatus == widget.task.status)
                                  return;
                                try {
                                  await taskService.updateTaskStatus(
                                    widget.task.id,
                                    newStatus,
                                  );
                                  ref.refresh(
                                    commentListProvider(widget.task.id),
                                  );
                                  ref.invalidate(taskServiceProvider);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status updated to ${_formatStatus(newStatus)}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update: $e'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              formatLabel: _formatStatus,
                            ),
                            _chip(
                              Icons.calendar_today_outlined,
                              "Due: ${DateFormat.yMMMd().format(widget.task.dueDate ?? DateTime.now())}",
                              Colors.teal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Comments Section
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.comment_outlined,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Comments",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            comments.maybeWhen(
                              data:
                                  (list) => Text(
                                    "${list.length} ${list.length == 1 ? 'comment' : 'comments'}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                              orElse: () => const SizedBox(),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        comments.when(
                          data:
                              (list) =>
                                  list.isEmpty
                                      ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.chat_bubble_outline,
                                                size: 48,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "No comments yet",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Be the first to add a comment",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: list.length,
                                        separatorBuilder:
                                            (_, __) =>
                                                const Divider(height: 32),
                                        itemBuilder: (_, i) {
                                          final c = list[i];
                                          final localTime =
                                              c.createdAt.toLocal();
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.deepPurple.shade100,
                                                child: Text(
                                                  c.username[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.deepPurple,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          c.username,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          "${DateFormat('MMM d').format(localTime)} at ${DateFormat('h:mm a').format(localTime)}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.grey.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        c.text,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                          loading:
                              () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          error:
                              (e, _) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Error loading comments",
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        e.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comment input bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.deepPurple,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    elevation: 2,
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
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
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }

  Widget _dropdownChip({
    required IconData icon,
    required String value,
    required List<String> options,
    required Color color,
    required ValueChanged<String?> onChanged,
    String Function(String)? formatLabel,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.arrow_drop_down, color: color),
          isDense: true,
          items:
              options
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s,
                      child: Text(formatLabel != null ? formatLabel(s) : s),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.only(right: 4),
    );
  }
}
