import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_styles.dart';
import 'conversation_list_screen.dart';


/*
This is a stateful widget that displays a list of conversations.
It contains the fields for the ConversationListScreen widget.
*/
class FeedbackScreen extends StatefulWidget {
  final String userId;

  const FeedbackScreen({super.key, required this.userId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

/*
This is a state class for the FeedbackScreen widget.
It contains the fields for the FeedbackScreen widget.
*/
class _FeedbackScreenState extends State<FeedbackScreen> {
  int satisfaction = 0;
  int easeOfUse = 0;
  int relevance = 0;
  int performance = 0;
  int design = 0;
  TextEditingController commentController = TextEditingController();
  bool isLoading = true;

  /*
  This is the constructor for the FeedbackScreen widget.
  It initializes the state of the widget.
  */
  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  /*
  This method loads the existing feedback values from the database by calling the backend API.
  It then updates the state of the widget with the existing feedback values.
  */
  Future<void> _loadFeedback() async {
    try {
      final existing = await ApiService.getFeedbackByUserId(widget.userId);
      if (existing != null) {
        setState(() {
          satisfaction = existing['satisfaction'];
          easeOfUse = existing['ease_of_use'];
          relevance = existing['relevance'];
          performance = existing['performance'];
          design = existing['design'];
          commentController.text = existing['comments'] ?? "";
        });
      }
    } catch (_) {
      // Ignore if not found
    } finally {
      setState(() => isLoading = false);
    }
  }

  /*
  This method submits the feedback to the database by calling the backend API.
  It then shows a snackbar to the user to confirm that the feedback has been submitted.
  After the feedback is submitted, it navigates to the ConversationListScreen.
  */
  Future<void> _submit() async {
    try {
      await ApiService.submitFeedback(
        userId: widget.userId,
        satisfaction: satisfaction,
        easeOfUse: easeOfUse,
        relevance: relevance,
        performance: performance,
        design: design,
        comments: commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationListScreen(userId: widget.userId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    }
  }


  /*
  This method builds the rating bar for the feedback screen.
  It returns a column of text and rating bar.
  */
  Widget _buildRating(String label, int value, Function(double) onRatingUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        RatingBar.builder(
          initialRating: value.toDouble(),
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: onRatingUpdate,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /*
  This method builds the feedback screen UI.
  There are 5 rating bars and a text field for additional comments.
  The ratings are converted to integers and stored in the state of the widget.
  The user can submit the feedback by pressing the submit button.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: "Provide Feedback"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildRating("1. Overall satisfaction", satisfaction, (val) => satisfaction = val.toInt()),
                  _buildRating("2. Ease of use", easeOfUse, (val) => easeOfUse = val.toInt()),
                  _buildRating("3. Relevance/Correctness of answers", relevance, (val) => relevance = val.toInt()),
                  _buildRating("4. Performance (speed & response)", performance, (val) => performance = val.toInt()),
                  _buildRating("5. UI Design", design, (val) => design = val.toInt()),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    cursorColor: AppColors.greenDark,
                    decoration: AppInputDecorations.textField("Additional Comments")
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[900],
                      foregroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Submit Feedback", style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
    );
  }
}
