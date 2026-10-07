import 'dart:convert';

/*
This is a model class for a Message.
It contains the fields for the Message object.
*/
class Message {
  final String role;
  final String message;
  final DateTime timestamp;

  Message({required this.role, required this.message, required this.timestamp});

  /*
  This is a factory constructor that creates a Message object from a JSON map.
  It takes a Map<String, dynamic> as an argument, which contains the data for the Message object.
  The factory constructor is used to create an instance of the Message class from a JSON map.
  */
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['sender'],
      message: utf8.decode(json['message'].codeUnits),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
