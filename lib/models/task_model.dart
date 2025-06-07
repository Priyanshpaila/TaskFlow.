class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> assignedTo;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final String createdBy;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['_id'],
    title: json['title'],
    description: json['description'],
    assignedTo:
        (json['assignedTo'] as List)
            .map((user) => user is String ? user : user['_id'] as String)
            .toList(),
    priority: json['priority'],
    status: json['status'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    createdBy:
        json['createdBy'] is String
            ? json['createdBy']
            : json['createdBy']['_id'],
  );
}
