import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String userId;
  final String displayName;
  final String photoUrl;

  UserModel(
      {required this.userId,
      required this.displayName,
      required this.photoUrl});
}

class FetchUsersScreen extends StatefulWidget {
  @override
  State<FetchUsersScreen> createState() => _FetchUsersScreenState();
}

class _FetchUsersScreenState extends State<FetchUsersScreen> {
  List<UserModel> chatUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    List<UserModel> userList = [];

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (QueryDocumentSnapshot userDoc in querySnapshot.docs) {
        String userId = userDoc.id;
        String displayName = userDoc['displayName'] ?? '';
        String photoUrl = userDoc['photoURL'] ?? '';
        userList.add(UserModel(
          userId: userId,
          displayName: displayName,
          photoUrl: photoUrl,
        ));
      }
      setState(() {
        chatUsers = userList; // Update the chatUsers list
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> initiateChat(
      String otherUserId, String PhotoURL, String Name) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        // Handle the case where the current user ID is empty (not signed in)
        print('Error: Current user not signed in');
        return;
      }
      String chatId = '${currentUserId.trim()}_${otherUserId.trim()}';
      String chatId1 = '${otherUserId.trim()}_${currentUserId.trim()}';
      CollectionReference messagesCollection =
          FirebaseFirestore.instance.collection('messages/$chatId/Chats');

      // Get the documents in the collection
      QuerySnapshot querySnapshot = await messagesCollection.get();

      // Return the count of documents
      CollectionReference messagesCollection1 =
          FirebaseFirestore.instance.collection('messages/$chatId1/Chats');

      // Get the documents in the collection
      QuerySnapshot querySnapshot1 = await messagesCollection1.get();

      print("------------------------------>");
      int sz1 = querySnapshot.size;
      int sz2 = querySnapshot1.size;

      if (sz1 != 0) {
        Navigator.pushNamed(context, '/chat', arguments: {
          "Chatid": '${currentUserId.trim()}_${otherUserId.trim()}',
          "PhotoURL": "${PhotoURL}",
          "Name": "${Name}",
        });
        return;
      }
      if (sz2 != 0) {
        Navigator.pushNamed(context, '/chat', arguments: {
          "Chatid": '${otherUserId.trim()}_${currentUserId.trim()}',
          "PhotoURL": "${PhotoURL}",
          "Name": "${Name}",
        });
        return;
      }
      if (querySnapshot.size == 0 && querySnapshot1.size == 0) {
        // If neither chatId exists, create currentId_chatId
        final Chatid = '${currentUserId.trim()}_${otherUserId.trim()}'.trim();
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(Chatid)
            .collection('Chats') // Assuming 'Chats' is the subcollection name
            .add({
          'userID': 'system',
          'Message': 'Chat started',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      Navigator.pushNamed(context, '/chat', arguments: {
        "Chatid": '${currentUserId.trim()}_${otherUserId.trim()}',
        "PhotoURL": "${PhotoURL}",
        "Name": "${Name}",
      });
    } catch (e) {
      print('Error initiating chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () {
              Future<void> logout() async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              }

              logout();
            },
            icon: const Icon(Icons.logout_outlined),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatUsers.length,
              itemBuilder: (BuildContext context, int index) {
                UserModel user = chatUsers[index];

                return GestureDetector(
                  onTap: () {
                    initiateChat(user.userId, user.photoUrl, user.displayName);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      child: Image.network(
                        user.photoUrl,
                        scale: 1.0,
                      ),
                    ),
                    title: Text(user.displayName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
