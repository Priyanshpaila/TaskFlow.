import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../models/comment_model.dart';

class CommentService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Comment>> fetchComments(String taskId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/comments/$taskId'),
      headers: {"Authorization": "Bearer $token"},
    );
    final List jsonList = json.decode(res.body);
    return jsonList.map((e) => Comment.fromJson(e)).toList();
  }

  Future<void> addComment(String taskId, String text) async {
    final token = await _getToken();
    await http.post(
      Uri.parse('$baseUrl/comments'),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({'taskId': taskId, 'text': text}),
    );
  }
}
