import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'conversation_list_screen.dart';
import '../theme/app_styles.dart';
import '../widgets/custom_app_bar.dart';

/*
This is a stateful widget that displays a OTP verification screen.
It contains the fields for the OTPVerificationScreen widget.
*/
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({required this.email, super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

/*
This is a state class for the OTPVerificationScreen widget.
It contains the fields for the OTPVerificationScreen widget.
*/
class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  String? _error;
  bool _isVerifying = false;

  /*
  This is the method that is called to verify the OTP.
  It calls the backend API with the email and OTP and verifies the OTP.
  If the OTP is verified, the user is redirected to the conversation list screen.
  If the OTP is not verified, the error message is shown.
  */
  void _verifyOtp() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final userId = await ApiService.verifyOtp(
        widget.email,
        _otpController.text.trim(),
      );

      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ConversationListScreen(userId: userId)),
        );
      } else {
        setState(() => _error = "Invalid OTP");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  /*
  This is the method that is called to build the widget. The method that builds the UI of the widget.
  It shows the email that the OTP was sent to and a text field for the user to enter the OTP.
  It also shows a circular progress indicator if the OTP is being verified.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: "OTP Verification"),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            "OTP sent to ${widget.email}",
            style: TextStyle(
            color: Colors.green[900],
            fontWeight: FontWeight.w500,
              ),
            ),
          ),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: AppInputDecorations.textField("Enter OTP"),
              cursorColor: Colors.green[900],
              style: TextStyle(color: Colors.green[900]),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            _isVerifying
                ? CircularProgressIndicator(color: Colors.green[900])
                : ElevatedButton(
                    style: AppButtonStyles.elevated,
                    onPressed: _verifyOtp,
                    child: const Text("Verify"),
                  ),
          ],
        ),
      ),
    );
  }
}
