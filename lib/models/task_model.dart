class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> assignedTo;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime? createdAt; // ✅ Added field
  final String createdBy;
  final String division;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.priority,
    required this.status,
    this.dueDate,
    this.createdAt, // ✅ Include in constructor
    required this.createdBy,
    required this.division,
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
    dueDate:
        json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
    createdAt:
        json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null, // ✅ Safe parse
    createdBy:
        json['createdBy'] is String
            ? json['createdBy']
            : json['createdBy']['_id'],
    division: json['division'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'assignedTo': assignedTo,
    'priority': priority,
    'status': status,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(), // ✅ Include in toJson
    'createdBy': createdBy,
    'division': division,
  };
}
