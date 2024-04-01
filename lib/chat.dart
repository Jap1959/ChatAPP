import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat/MessageBubble.dart';
import 'package:intl/intl.dart'; // Assuming you have a MessageBubble widget

String formatTimestamp(Timestamp? timestamp) {
  // Convert timestamp to DateTime
  DateTime dateTime = timestamp == null ? DateTime.now() : timestamp.toDate();

  // Format DateTime object as desired
  String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);

  return formattedDateTime;
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String Name;
  final String photoURL;

  ChatScreen(
      {required this.chatId, required this.Name, required this.photoURL});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Stream<QuerySnapshot> _messageStream;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageStream = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('Chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String message) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        print('Error: Current user not signed in');
        return;
      }

      Map<String, dynamic> messageData = {
        'userID': currentUserId,
        'Message': message,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatId)
          .collection('Chats')
          .add(messageData);

      messageController.clear(); // Clear the message input field
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.Name),
        leading: Column(
          children: [
            CircleAvatar(
              child: Image.network(
                widget.photoURL,
                scale: 0.01,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<DocumentSnapshot> messageDocs =
                    snapshot.data?.docs ?? []; // Get the message documents

                return ListView.builder(
                  reverse: true,
                  itemCount: messageDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> messageData =
                        messageDocs[index].data() as Map<String, dynamic>;
                    return MessageBubble(
                        message: messageData['Message'],
                        isMe: messageData['userID'] ==
                            (FirebaseAuth.instance.currentUser?.uid ?? ''),
                        isSystem: messageData['userID'] == 'system',
                        time: formatTimestamp(messageData['timestamp']));
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      sendMessage(messageController.text);
                    }
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
