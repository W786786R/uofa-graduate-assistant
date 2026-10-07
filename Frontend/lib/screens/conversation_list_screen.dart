import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uofa_graduate_assistant/main.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';
import 'new_chat_screen.dart';
import 'feedback_screen.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import '../utils/download_conversation.dart';

/*
This is a stateful widget that displays a list of conversations.
It contains the fields for the ConversationListScreen widget.
*/
class ConversationListScreen extends StatefulWidget {
  final String userId;
  const ConversationListScreen({super.key, required this.userId});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

/*
This is a state class for the ConversationListScreen widget.
It contains the fields for the ConversationListScreen widget.
*/
class _ConversationListScreenState extends State<ConversationListScreen> with RouteAware {
  List<Conversation> _conversations = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _allConversations = []; // Original unfiltered list

  /*
  This is the constructor for the ConversationListScreen widget.
  It initializes the state of the widget.
  */
  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  /*
  This is the method that is called when the dependencies of the widget change.
  It is used to subscribe to the route observer.
  */
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      getRouteObserver().subscribe(this, route);
    }
  }

  /*
  This is the method that is called when the widget is disposed.
  It is used to unsubscribe from the route observer.
  */
  @override
  void dispose() {
    getRouteObserver().unsubscribe(this);
    super.dispose();
  }

  /*
  This is the method that is called when the widget is popped.
  It is used to clear the search controller and reset the conversations.
  It also fetches the conversations again.
  */
  @override
  void didPopNext() {
    // Called when returning from NewChatScreen
  setState(() {
    _searchController.clear();         // Clear the search bar text
    _conversations = _allConversations; // Reset immediately
  });
  _fetchConversations();
  
}

  /*
  This is the method that is called to fetch the conversations.
  It is used to fetch the conversations using the API.
  It also updates the state of the widget to show the conversations.
  */
  void _fetchConversations() async {
    try {
      final conversations = await ApiService.getConversations(widget.userId);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _allConversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /*
  This is the method that is called to filter the conversations.
  It is used to retrieve the conversations based on the search keyword using the API.
  It also updates the state of the widget to show the filtered conversations.
  */
  void _filterConversations(String keyword) async {
  if (keyword.isEmpty) {
    setState(() => _conversations = _allConversations);
    return;
  }

  final filtered = await ApiService.searchConversations(widget.userId, keyword);
  if (!mounted) return;
  setState(() => _conversations = filtered);
}

  /*
  This is the method that is called to delete a conversation.
  It is used to delete a conversation using the API.
  */
  void _deleteConversation(int conversationId) async {
    await ApiService.deleteConversation(conversationId);
    _fetchConversations();
  }

  /*
  This is the method that is called to logout.
  It is used to clear the user id from the shared preferences and navigate to the login screen.
  */
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /*
  This is the method that is called to change the title of a conversation.
  It is used to change the title of a conversation using the API.
  It  shows a dialog to the user to enter the new title and save it.
  New title is limited to 30 characters.
  */
  void _changeTitle(int conversationId) async {
    final controller = TextEditingController();
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellow,
        title: Text(
          "Change Conversation Title ( Max. 20 Characters)",
          style: TextStyle(color: Colors.green[900]),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.green[900]),
          cursorColor: Colors.green[900],
          decoration: InputDecoration(
            hintText: "Enter new title",
            hintStyle: TextStyle(color: Colors.green[900]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[900]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[900]!),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.green[900])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text("Save", style: TextStyle(color: Colors.green[900])),
          ),
        ],
      ),

    );

    /*
    This ensure that the new title is not empty and is not more than 20 characters.
    It then updates the title of the conversation using the API.
    */
    if (newTitle != null && newTitle.isNotEmpty) {
      final convTitle =  newTitle.length > 20 ? '${newTitle.substring(0, 20)}...' : newTitle;
      await ApiService.updateConversationTitle(conversationId, convTitle);
      _fetchConversations();
    }
  }


  /*
  This is the method that is called to build the widget. The method that builds the UI of the widget.
  It is used to build the widget.
  It also shows a loading indicator if the conversations are still loading.
  It also shows the conversations in a list view.
  It also shows a floating action button to start a new conversation.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: CustomAppBar.build(
        title: "Your Conversations",
        showBack: false,
        leading: Padding( //This is UI for the feedback button. It loads the feedback icon from the assets folder.
          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
          child: Align(
            alignment: Alignment.center,
            child: Tooltip(
              message: 'Feedback',
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset('assets/images/feedback_logo_clean.png', height: 50, width: 50),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0, top: 16.0),
            child: Align(
              alignment: Alignment.center,
              child: Tooltip(
                message: 'Logout',
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Image.asset('assets/images/logout.png', height: 50, width: 50),
                  onPressed: _logout,
                ),
              ),
            ),
          ),
        ],

      ),

      /*
      This is the body of the conversation list screen.
      It is used to display the conversations in a list view.
      It also shows a search bar to search for a conversation.
      It also shows a floating action button to start a new conversation.
      */
      body: _loading
    ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 12, 71, 16)))
    : Column(         //This is the column that contains the search bar and the list of conversations.
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConversations,
              style: TextStyle(color: Colors.green[900]),
              cursorColor: Colors.green[900],
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.green[900]),
                prefixIcon: Icon(Icons.search, color: Colors.green[900]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green[900]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green[900]!),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
          Expanded(
            child: ListView.builder( //This is the list view that contains the conversations.
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final convo = _conversations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewChatScreen( //If the user clicks on a conversation, the user is redirected to the new chat screen.
                              userId: widget.userId,
                              conversationId: convo.id,
                              title: convo.title,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    convo.title,
                                    style: TextStyle(fontSize: 18, color: Colors.green[900]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Updated on ${convo.updatedAt.toLocal().toString().substring(0, 19)}",
                                    style: TextStyle(fontSize: 12, color: Colors.green[900]),
                                  ),
                                ],
                              ),
                            ),
                            /*
                            This is the popup menu button that is used to show the options for the conversation.
                            It is used to delete a conversation, change the title of a conversation and download the conversation.
                            */
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.green[900]),
                              color: Colors.green[900],
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteConversation(convo.id);
                                } else if (value == 'rename') {
                                  _changeTitle(convo.id);
                                }
                                else {
                                    DownloadUtils.downloadConversation(
                                    context: context,
                                    conversationId: convo.id,
                                    title: convo.title,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    "Delete Conversation",
                                    style: TextStyle(color: Colors.yellow),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text(
                                    "Change Title",
                                    style: TextStyle(color: Colors.yellow),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'conv_share',
                                  child: Text(
                                    "Download Conversation",
                                    style: TextStyle(color: Colors.yellow),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
    ),
    /*
    This is the floating action button that is used to start a new conversation.
    It calls the backend API to create a new conversation and then navigates to the new chat screen.
    */
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.yellow,
        onPressed: () async {
          final newConvo = await ApiService.startConversation(widget.userId);
          if (!mounted) return;
          if (newConvo != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewChatScreen(
                  userId: widget.userId,
                  conversationId: newConvo['conversation_id'],
                  title: newConvo['title'] ?? 'New Chat', // If the conversation title is not provided, it defaults to 'New Chat'
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}