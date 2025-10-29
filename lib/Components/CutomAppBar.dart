import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/color_constants.dart';

class CustomAppBar1 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? color;
  final List<Widget> actions;

  const CustomAppBar1({Key? key, required this.title, required this.actions,this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      AppBar(
      backgroundColor: color??Colors.white,
      centerTitle: true,
      leading: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () {
          context.pop(true);
        },
        icon: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
