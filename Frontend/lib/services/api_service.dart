import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/conversation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;


class ApiService {
  /*
  This is the base URL of the backend API.
  It is used to send requests to the backend API.
  We are setting the URL based on the type of Platform we are running the app in.
  */

  static String determineBaseURL (){
  if (kIsWeb) {
    // Web browser (Chrome, Edge, etc.)
    return "http://localhost:8000"; // Or your hosted backend
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:8000"; // Android emulator
  } else if (Platform.isIOS) {
    return "http://localhost:8000"; // iOS simulator
  } else {
    return "http://localhost:8000"; // Default fallback for desktop, etc.
  }
}
  static String baseUrl = determineBaseURL();
  /*
  This is the method that is called to register a user.
  It calls the backend API with the user's first name, last name, email and password.
  If the user is registered successfully, the user's id is returned.
  If the user is not registered successfully, the error message is thrown.
  */
  static Future<String> register(String first, String last, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': first,
        'last_name': last,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['user_id'] ?? email;
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  /*
  This is the method that is called to get the conversations of a user.
  It calls the backend API with the user's id.
  If the conversations are loaded successfully, the conversations are returned.
  If the conversations are not loaded successfully, the error message is thrown.
  It uses the conversation model to parse the conversations.
  */
  static Future<List<Conversation>> getConversations(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/conversations/$userId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load conversations");
    }
  }

  /*
  This is the method that is called to start a new conversation.
  It calls the backend API with the user's id.
  If the conversation is started successfully, the conversation id is returned.
  If the conversation is not started successfully, the error message is thrown.
  */
  static Future<Map<String, dynamic>?> startConversation(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  /*
  This is the method that is called to update the title of a conversation.
  It calls the backend API with the conversation id and the new title.
  If the title is updated successfully, the conversation id is returned.
  If the title is not updated successfully, the error message is thrown.
  */
  static Future<void> updateConversationTitle(int convoId, String title) async {
    final response = await http.put(
      Uri.parse('$baseUrl/conversations/update-title'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "conversation_id": convoId,
        "new_title": title,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update title");
    }
  }

  /*
  This is the method that is called to get the messages of a conversation.
  It calls the backend API with the conversation id.
  If the messages are loaded successfully, the messages are returned.
  If the messages are not loaded successfully, the error message is thrown.
  It uses the message model to parse the messages.
  */
  static Future<List<Message>> getMessagesByConversationId(int convoId) async {
    final response = await http.get(Uri.parse('$baseUrl/messages/$convoId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Message.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  /*
  This is the method that is called to send a message to a conversation.
  It calls the backend API with the conversation id, the sender and the message.
  If the message is sent successfully, the message is returned.
  If the message is not sent successfully, the error message is thrown.
  The utf8.decode(response.bodyBytes) is used to decode the response body so that the special characters are not lost.
  */
  static Future<Map<String, dynamic>> sendMessageToConversation({
    required int conversationId,
    required String sender,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversation_id': conversationId,
        'sender': sender,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      //log.info("RESPONSE BODY ${utf8.decode(response.bodyBytes)}"); //Debug Prints the response body
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to send message");
    }
  }

  /*
  This is the method that is called to delete a conversation.
  It calls the backend API with the conversation id.
  If the conversation is deleted successfully, the conversation id is returned.
  If the conversation is not deleted successfully, the error message is thrown.
  */
  static Future<void> deleteConversation(int conversationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/conversations/$conversationId'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete conversation");
    }
  }

  /*
  This is the method that is called to search for a conversation.
  It calls the backend API with the user's id and the search keyword.
  If the conversation is found successfully, the conversation is returned.
  If the conversation is not found successfully, the error message is thrown.
  */
  static Future<List<Conversation>> searchConversations(String userId, String keyword) async {
    final response = await http.get(Uri.parse('$baseUrl/search-conversations/$userId?q=$keyword'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Conversation.fromJson(e)).toList();
    } else {
      throw Exception("Search failed");
    }
  }

  /*
  This is the method that is called to request an OTP.
  It calls the backend API with the user's email and password. If the user exists, status 200 is received.
  If the user does not exist, status 401 is received.
  If the OTP is requested successfully, OK is returned.
  If the OTP is not requested successfully, Failed to send OTP/ Invalid email or password is returned.
  */
  static Future<String> requestOtp(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200)
    {
        return "OK";
    }
    else if (response.statusCode == 401)
    {
        return "Invalid email or password";
    }
    else
    {
        return "Failed to send OTP";
    }
  }

  /*
  This is the method that is called to verify the OTP.
  It calls the backend API with the user's email and OTP.
  If the OTP is verified successfully, the user's id is returned.
  If the OTP is not verified successfully, null is returned.
  */
  static Future<String?> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user_id'];
    }
    return null;
  }

  /*
  This is the method that is called to get the text messages of a conversation.
  It calls the backend API with the conversation id amd receives all of the messages in the conversation as a string.
  If the conversation text is loaded successfully, the conversation text is returned.
  If the conversation text is not loaded successfully, the error message is thrown.
  */
  static Future<String> getConversationText(int conversationId) async {
      final response = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'));
      
    if (response.statusCode == 200) {
      return response.body; // plain text
    } else {
      throw Exception('Failed to fetch conversation messages');
    }
  }

  /*
  This is the method that is called to submit the feedback.
  It calls the backend API with the user's id and the feedback values.
  If the feedback is submitted successfully, the feedback is returned.
  If the feedback is not submitted successfully, the error message is thrown.
  */
  static Future<void> submitFeedback({
    String? userId,
    int? satisfaction,
    int? easeOfUse,
    int? relevance,
    int? performance,
    int? design,
    String? comments,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/submit-feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId ?? '',
        'satisfaction': satisfaction ?? 0,
        'ease_of_use': easeOfUse ?? 0,
        'relevance': relevance ?? 0,
        'performance': performance ?? 0,
        'design': design ?? 0,
        'comments': comments ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to submit feedback");
    }
  }

  /*
  This is the method that is called to get the existing feedback of a user.
  It calls the backend API with the user's id.
  If the feedback is loaded successfully, the feedback values are returned.
  If the feedback is not loaded successfully, the error message is thrown based on the status code.
  */
  static Future<Map<String, dynamic>?> getFeedbackByUserId(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/fetch-feedback/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // No feedback found
    } else {
      throw Exception("Failed to fetch feedback");
    }
  }

}


