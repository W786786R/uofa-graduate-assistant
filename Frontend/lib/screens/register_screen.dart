import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../theme/app_styles.dart';
import '../widgets/custom_app_bar.dart';

/*
This is a stateful widget that displays a register screen.
It contains the fields for the RegisterScreen widget.
*/
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/*
This is a state class for the RegisterScreen widget.
It contains the fields for the RegisterScreen widget.
*/
class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasDigit = false;
  bool hasSpecialChar = false;

  /*
  This is the method that is called to updated the states of the variables that are used to check the password format.
  The password must contain at least one uppercase letter, one lowercase letter, one number and one special character.
  It uses regular expressions to check the password format.
  */
  void _checkPassword(String password) {
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]')); //Checks if the password contains an uppercase letter
      hasLowercase = password.contains(RegExp(r'[a-z]')); //Checks if the password contains a lowercase letter
      hasDigit = password.contains(RegExp(r'[0-9]')); //Checks if the password contains a number
      hasSpecialChar = password.contains(RegExp(r'[!@#\\$%^&*(),.?":{}|<>]')); //Checks if the password contains a special character
    });
  }

  /*
  This is the method that is called to check if the email is valid.
  The email must contain an at symbol and a dot.
  It uses regular expressions to check the email format.
  */
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /*
  This is the method that is called to check if the password is valid.
  The password must contain at least one uppercase letter, one lowercase letter, one number and one special character.
  It uses the variables that are updated in the _checkPassword method to check the password format.
  */
  bool _isPasswordValid() {
    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  /*
  This is the method that is called to register the user.
  It only registers the user if the email and password are valid.
  It calls the backend API with the user's first name, last name, email and password.
  If the user is registered successfully, the user is redirected to the login screen.
  If the user is not registered successfully, the error message is shown.
  */
  void _register() async {
    setState(() {
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() => _error = "Invalid email format");
      return;
    }

    if (!_isPasswordValid()) {
      setState(() => _error = "Password does not meet the requirements");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await ApiService.register(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        email.toLowerCase(),
        password,
      ); //Calls the backend API with the user's first name, last name, email and password

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId); //Saves the user's id to the shared preferences so that the user can be logged in automatically

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        ); //Pushes the user to the login screen and removes all the other screens from the stack
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /*
  This is the method defines the rules providing live feedback on the password format.
  It shows a checkmark if the rule is valid and a cross if the rule is not valid.
  */
  Widget _buildRule(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green[900] : Colors.red, size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: isValid ? Colors.green[900] : Colors.red)),
      ],
    );
  }

  /*
  This is the method that is called to build the widget.
  It shows the registration form and the rules for the password.
  It also shows a circular progress indicator if the user is registering.   
  It also shows an error message if the user is not registered successfully.
  It also provides live feedback on the password format.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: "Registration"),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),

              TextField(
                controller: _firstNameController,
                decoration: AppInputDecorations.textField("First Name"),
                cursorColor: Colors.green[900],
                style: TextStyle(color: Colors.green[900]),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _lastNameController,
                decoration: AppInputDecorations.textField("Last Name"),
                cursorColor: Colors.green[900],
                style: TextStyle(color: Colors.green[900]),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                decoration: AppInputDecorations.textField("Email"),
                cursorColor: Colors.green[900],
                style: TextStyle(color: Colors.green[900]),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                onChanged: _checkPassword,
                decoration: AppInputDecorations.textField("Password"),
                obscureText: true,
                cursorColor: Colors.green[900],
                style: TextStyle(color: Colors.green[900]),
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRule("At least one uppercase letter", hasUppercase),
                  _buildRule("At least one lowercase letter", hasLowercase),
                  _buildRule("At least one number", hasDigit),
                  _buildRule("At least one special character", hasSpecialChar),
                ],
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator(color: Color.fromARGB(255, 12, 71, 16))
                  : ElevatedButton(
                      style: AppButtonStyles.elevated,
                      onPressed: _register,
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
