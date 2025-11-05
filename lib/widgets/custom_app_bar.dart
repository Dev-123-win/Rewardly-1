import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBack,
            )
          : null,
      title: Text(title),
      actions: actions,
    );
  }
}
