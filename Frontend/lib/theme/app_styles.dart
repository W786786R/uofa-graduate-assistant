import 'package:flutter/material.dart';

/*
This is the class that contains the colors of the app.
It is used to store the colors of the app.
*/ 
class AppColors {
  static final green = Colors.green[800]!;
  static final greenLight = Colors.green[300]!;
  static final greenDark = Colors.green[900]!;
  static const white = Colors.white;
  static const error = Colors.red;
}

/*
This is the class that contains the text styles of the app.
It is used to store the text styles of the app.
*/
class AppTextStyles {
  /*
  This is the text style for the title of the app.
  It is used to display the title of the app in particular font size and color.
  */
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  /*
  This is the text style for the input label of the app.
  It is used to display the input label of the app in particular color.
  */
  static final inputLabel = TextStyle(
    color: AppColors.greenDark,
  );

  /*
  This is the text style for the link text of the app.
  It is used to display the link text of the app in particular color. The Create Account link is shown in this style.
  */
  static const linkText = TextStyle(
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.bold,
  );
}

/*
This is the class that contains the input text field decorations of the app.
It is used to store the input text field decorations of the app.
*/
class AppInputDecorations {
  /*
  This is the input decoration for the text field of the app.
  It is used to display the text field of the app in particular color.
  */
  static InputDecoration textField(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.inputLabel,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.green),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.greenLight),
      ),
    );
  }
}

/*
This is the class that contains the button styles of the app.
It is used to store the button styles of the app.
*/
class AppButtonStyles {
  /*
  This is the button style for the elevated button of the app.
  It is used to display the elevated button of the app in particular color.
  */
  static final elevated = ElevatedButton.styleFrom(
    backgroundColor: AppColors.greenDark,
    foregroundColor: AppColors.white,
  );
}
