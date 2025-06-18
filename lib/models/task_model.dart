class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> assignedTo;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String createdBy;
  final String division;
  final String? reason; // ✅ New field

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.priority,
    required this.status,
    this.dueDate,
    this.createdAt,
    required this.createdBy,
    required this.division,
    this.reason, // ✅ Include in constructor
  });

  /// ✅ Factory constructor to build Task from JSON
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
        json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    createdBy:
        json['createdBy'] is String
            ? json['createdBy']
            : json['createdBy']['_id'],
    division: json['division'] ?? '',
    reason: json['reason'], // ✅ Deserialize reason
  );

  /// ✅ Convert Task to JSON
  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'assignedTo': assignedTo,
    'priority': priority,
    'status': status,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'createdBy': createdBy,
    'division': division,
    'reason': reason, // ✅ Serialize reason
  };

  /// ✅ Helper: Check if task is personal/self-assigned
  bool get isPersonalTask =>
      assignedTo.length == 1 && assignedTo.first == createdBy;
  bool get isForwarded => status == 'forward';
  bool get isAborted => status == 'abort';
  bool get needsReason => isForwarded || isAborted;
}
