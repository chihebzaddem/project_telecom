import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions; // ✅ Allow optional custom buttons

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions, // ✅ If null, nothing is shown
      leading: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: SvgPicture.asset(
          'assets/logo.svg',
          height: 40,
          width: 40,
          fit: BoxFit.contain,
        ),
      ),
      leadingWidth: 60,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
