// lib/state/division_state.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';

final divisionListProvider = StateNotifierProvider<DivisionNotifier, List<String>>((ref) {
  return DivisionNotifier();
});

class DivisionNotifier extends StateNotifier<List<String>> {
  DivisionNotifier() : super([]);

  Future<void> fetchDivisions() async {
    try {
      final response = await http.get(Uri.parse(getDivisionsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = data.map((e) => e['name'].toString()).toList();
      }
    } catch (e) {
      print('Failed to fetch divisions: $e');
    }
  }

  Future<void> addDivision(String name) async {
    try {
      final response = await http.post(
        Uri.parse(addDivisionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );
      if (response.statusCode == 201) {
        await fetchDivisions();
      }
    } catch (e) {
      print('Failed to add division: $e');
    }
  }
}
