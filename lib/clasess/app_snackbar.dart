import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
      BuildContext context,
      String message, {
        Color? backgroundColor,
        IconData? icon,
      }) {
    final theme = Theme.of(context);

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: theme.snackBarTheme.contentTextStyle?.color ?? Colors.white,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.snackBarTheme.contentTextStyle,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? theme.snackBarTheme.backgroundColor,
      behavior: theme.snackBarTheme.behavior ?? SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12), // هنا ثابت
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // هنا ثابت
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
