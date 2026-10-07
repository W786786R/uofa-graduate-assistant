import 'package:flutter/material.dart';

/*
This is the class that contains the custom app bar of the app.
It is used to display the app bar of all of the screens in our desired format and color
*/
class CustomAppBar {
  static AppBar build({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    bool showBack = true,
    Widget? leading,
  }) {
    return AppBar(
      backgroundColor: Colors.green[900],
      toolbarHeight: 80,
      centerTitle: centerTitle,
      title: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      automaticallyImplyLeading: showBack,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
