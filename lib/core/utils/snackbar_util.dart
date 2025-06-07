// core/utils/snackbar_util.dart
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {bool error = false}) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: error ? Colors.red : Colors.green,
    behavior: SnackBarBehavior.floating,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
