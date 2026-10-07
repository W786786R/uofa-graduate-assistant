
/*
This is a model class for a Conversation.
It contains the fields for the Conversation object.
*/
class Conversation {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({required this.id, required this.title, required this.createdAt, required this.updatedAt});

  /*
  This is a factory constructor that creates a Conversation object from a JSON map.
  It takes a Map<String, dynamic> as an argument, which contains the data for the Conversation object.
  The factory constructor is used to create an instance of the Conversation class from a JSON map.
  */
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
