import 'package:flutter/material.dart';

/// Shows a short message at the bottom of the screen.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Asks the user to confirm an action and returns whether they did.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  bool destructive = false,
}) async {
  final colours = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colours.error,
                  foregroundColor: colours.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Formats a duration in minutes, for example "45 min" or "1 hr 30 min".
String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours hr' : '$hours hr $rest min';
}
