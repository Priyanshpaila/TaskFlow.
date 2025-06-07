import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

final commentServiceProvider = Provider<CommentService>((ref) => CommentService());

final commentListProvider = FutureProvider.family<List<Comment>, String>((ref, taskId) {
  return ref.watch(commentServiceProvider).fetchComments(taskId);
});
