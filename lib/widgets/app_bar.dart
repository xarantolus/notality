import 'package:flutter/material.dart';

class CustomAppBar {
  static AppBar create(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    List<Widget>? actions,
    Widget? icon,
  }) {
    return AppBar(
      centerTitle: true,
      title: title == null ? null : Text(title, style: titleStyle),
      leading: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Tooltip(message: title ?? "", child: icon),
            ),
      actions: actions,
    );
  }
}
