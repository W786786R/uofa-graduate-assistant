import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../logger.dart';
import '../widgets/custom_app_bar.dart';


/*
This screen is used for two purposes:
1. To start a new chat with the bot.
2. To continue a previous conversation with the bot.
If it is a new chat, the title is "New Chat".
If it is a previous conversation, the title is the title of the conversation.
*/


/*
This is a stateful widget that displays a new chat screen.
It contains the fields for the NewChatScreen widget.
*/
class NewChatScreen extends StatefulWidget {
  final String userId;
  final int conversationId;
  final String title;

  const NewChatScreen({
    super.key,
    required this.userId,
    required this.conversationId,
    required this.title,
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

/*
This is a state class for the NewChatScreen widget.
It contains the fields for the NewChatScreen widget.
*/
class _NewChatScreenState extends State<NewChatScreen> {
  late int conversationId;
  late String userId;
  late String title;
  bool isNewChat = false;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;


  /*
  This is the method that is called to initialize the state of the widget.
  It is used to initialize the state of the widget.
  */
  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId;
    userId = widget.userId;
    // If the title is empty or "New Chat", it is set to "New Chat"
    if (widget.title.trim().isEmpty || widget.title == "New Chat") {
      title = "New Chat";
      isNewChat = true;
  } else {
      title = widget.title;
      isNewChat = false;
  }
    _loadMessages(); //Loads the previous messages from the conversation
  }

  /*
  This is the method that is called to dispose of the widget.
  It is used to dispose of the widget.
  */
  @override
  void dispose() {
    if (isNewChat) {
      //Updates the conversation title AUTOMATICALLY during disposal with the first 30 characters of the first user message if it is a new chat
      _updateConversationTitleIfNeeded(); 
    }
    super.dispose();
  }

  /*
  This is the method that is called to load the previous messages from the conversation.
  */
  void _loadMessages() async {
      final msgs = await ApiService.getMessagesByConversationId(widget.conversationId);
      log.info("Loaded ${msgs.length} messages for conversation $conversationId");

      //If new conversation, show welcome message
      if (msgs.isEmpty) {
        setState(() {
          _messages = [
            Message(
              role: 'bot',
              message: "Hello, I am U of A Graduate Application Assistant. I can help you find out the application requirements, deadlines, faculty information for the Department of Computing Science. How can I assist you today?",
              timestamp: DateTime.now(),
            )
          ];
        });
      } else {
        setState(() => _messages = msgs);
      }
      _scrollToBottom(); //Scrolls to the bottom of the chat
    }

  /*
  This is the method that is called to scroll to the bottom of the chat to show the latest messages.
  */
  void _scrollToBottom({int attempts = 0}) {
  if (!_scrollController.hasClients) {
    if (attempts < 10) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom(attempts: attempts + 1);
      });
    }
    return;
  }

  final position = _scrollController.position;
  final maxScroll = position.maxScrollExtent;

  _scrollController.animateTo(
    maxScroll,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  if (attempts < 10) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (position.maxScrollExtent > maxScroll) {
        _scrollToBottom(attempts: attempts + 1);
      }
    });
  }
}


  /*
  This is the method that is called to update the conversation title if needed.
  */
  void _updateConversationTitleIfNeeded() async {
    try {
      final firstUserMessage = _messages.firstWhere(
        (msg) => msg.role == 'user',
        orElse: () => Message(role: '', message: '', timestamp: DateTime.now()),
      );

      //If the first user message is not empty, it updates the conversation title with the first 20 characters of the first user message
      if (firstUserMessage.message.isNotEmpty) {
        final trimmedMessage = firstUserMessage.message.trim();
        final newTitle = trimmedMessage.length > 20 ? '${trimmedMessage.substring(0, 20)}...' : trimmedMessage;
        await ApiService.updateConversationTitle(conversationId, newTitle); //Calls the backend API with the new title and conversation id
        log.info("Updated conversation title: \$newTitle");
      }
    } catch (e) {
      log.warning("Could not update conversation title: \$e");
    }
  }

  /*
  This is the method that is called to send a message to the conversation.
  */
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Updates the messages list with the user's message
    setState(() {
      _messages.add(Message(role: 'user', message: text, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _controller.clear();
     _scrollToBottom();

    try {
      final reply = await ApiService.sendMessageToConversation( //Calls the backend API with the user's message and conversation id and receives the reply from the bot
        conversationId: conversationId,
        sender: "user",
        message: text,
      );

      // If the reply is not null, it updates the messages list with the bot's message
      if (reply['bot_message'] != null) {
        setState(() {
          _messages.add(
            Message(
              role: 'bot',
              message: reply['bot_message']['message'],
              timestamp: DateTime.parse(reply['bot_message']['timestamp']),
            ),
          );
        });
        _scrollToBottom(); //Scrolls to the bottom of the chat to show the latest messages
        //log.info("LLaMA replied: \${reply['bot_message']['message']}"); //Debug Prints the reply from the bot
      }
    } catch (e, stackTrace) {
      log.severe("Error from LLaMA: \$e", e, stackTrace); //Debug Prints the error from the bot
      setState(() {
        _messages.add(Message(role: 'bot', message: "Oops! Something went wrong.", timestamp: DateTime.now())); //Updates the messages list with the error message
      });
      _scrollToBottom(); //Scrolls to the bottom of the chat to show the latest messages
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /*
  This is the method that is called to build the widget. The method that builds the UI of the widget.
  The user messages appear on the right and the bot messages appear on the left.
  The user message are Green and the bot messages are Yellow.
  If the background is Green, the text is Yellow and if the background is Yellow, the text is Green.
  It also creates a text field for the user to enter their message and a send button.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.build(title: title),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.role == 'user'
                            ? Colors.green[900]
                            : Colors.yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        msg.message,
                        style: TextStyle(
                          color: msg.role == 'user' ? Colors.yellow : Colors.green[900],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            //Creates a divider to separate the messages from the text field
            //Creates a text field for the user to enter their message and a send button.
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    style: TextStyle(color: Colors.green[900]),
                    cursorColor: Colors.green[900],
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: TextStyle(color: Colors.green[900]),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green[900]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green[900]!),
                      ),
                      disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[900]!),
                    ),
                    ),
                  ),

                  ),
                  //Creates a circular progress indicator to show that the message is being sent
                  const SizedBox(width: 8),
                  _isLoading
                      ? const CircularProgressIndicator(color: Color.fromARGB(255, 12, 71, 16))
                      : IconButton(
                          color: Colors.green[900],
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}