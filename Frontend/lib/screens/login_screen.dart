import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import '../theme/app_styles.dart';
import '../widgets/custom_app_bar.dart';
import 'otp_verification_screen.dart';

/*
This is a stateful widget that displays a login screen.
It contains the fields for the LoginScreen widget.
*/
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/*
This is a state class for the LoginScreen widget.
It contains the fields for the LoginScreen widget.
*/
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  /*
  This is the method that is called to request the OTP
  It takes the email and password from the text fields and sends it to the backend API for user verification.
  If the user is verified, the OTP is sent to the user's email and the user is redirected to the OTP verification screen.
  */
  void _requestOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ApiService.requestOtp(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text.trim(),
      );

      if (success == "OK") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(email: _emailController.text.trim().toLowerCase()),
          ),
        );
      } else {
        setState(() => _error = success);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /*
  This is the method that is called to build the widget. The method that builds the UI of the widget.
  It is used to build the widget.
  It also shows a loading indicator if the OTP is still loading.
  It also shows the error message if the OTP is not verified.
  It also shows the email and password text fields.
  It also shows the login button.
  It also shows the create account link.
  */
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar.build(title: "U of A Graduate Application Assistant"),
    body: Padding(
      padding: const EdgeInsets.all(24),
child: SingleChildScrollView(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Loads the University of Alberta Logo
      Image.asset(
        'assets/images/UofA_logo.png',
        height: 200,
      ),
      // Shows the error message if the OTP is not verified
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

      // Shows the email text field
          TextField(
            controller: _emailController,
            decoration: AppInputDecorations.textField("Email"),
            cursorColor: Colors.green[900],
            style: TextStyle(color: Colors.green[900]),
),

            const SizedBox(height: 12),

            // Shows the password text field
            TextField(
              controller: _passwordController,
              decoration: AppInputDecorations.textField("Password"),
              obscureText: true,
              cursorColor: Colors.green[900],
              style: TextStyle(color: Colors.green[900]),
            ),

            const SizedBox(height: 24),

            _isLoading
                ? const CircularProgressIndicator(color: Color.fromARGB(255, 12, 71, 16))
                : ElevatedButton(
                    style: AppButtonStyles.elevated,
                    onPressed: _requestOtp,
                    child: const Text("Login"),
                  ),

            const SizedBox(height: 24),

            // Shows the create account link. If the user does not have an account, they can create one.
            // It navigates to the register screen.
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: AppColors.greenDark),
                  children: [
                    TextSpan(
                      text: "Create Account",
                      style: AppTextStyles.linkText.copyWith(color: AppColors.greenDark),
                    ),
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    ),
  );
}
}
