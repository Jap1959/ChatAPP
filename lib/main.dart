  import 'package:chat/Auth.dart';
  import 'package:chat/chat.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Check if the user is already logged in
    var currentUser = FirebaseAuth.instance.currentUser;
    runApp(MyApp(initialRoute: currentUser != null ? '/users' : '/'));
  }

  class MyApp extends StatelessWidget {
    final String initialRoute;

    const MyApp({Key? key, required this.initialRoute}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const MyHomePage(title: 'Chat Application'),
          '/users': (context) => FetchUsersScreen(),
          '/chat': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final Map<String, dynamic> typedArgs = args as Map<String, dynamic>;
            final Name = typedArgs['Name'] ?? ' ';
            final Chatid = typedArgs['Chatid'] ?? ' ';
            final Photo = typedArgs['PhotoURL'] ?? ' ';
            return ChatScreen(
              chatId: Chatid,
              Name: Name,
              photoURL: Photo,
            );
          },
        },
      );
    }
  }

  class MyHomePage extends StatelessWidget {
    final String title;

    const MyHomePage({Key? key, required this.title}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await signInWithGoogle();
              var currentUser = FirebaseAuth.instance.currentUser;

              if (currentUser != null) {
                Navigator.pushReplacementNamed(context, '/users');
              } else {
                print('User is not logged in');
              }
            },
            child: const Text('Sign with Google'),
          ),
        ),
      );
    }
  }


  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        // Sign in to Firebase using the Google credential
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // Update Firebase user profile with Google user's display name and profile URL
        User? user = userCredential.user;
        if (user != null) {
          await user.updateProfile(
              displayName: googleUser.displayName, photoURL: googleUser.photoUrl);
          // Refresh the user object to get the updated profile data
          await user.reload();

          // Add user details to Firestore collection
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            // Add other user details if needed
          });

          // Return the updated user credential
          return userCredential;
        } else {
          throw 'User not found after signing in';
        }
      }
      return null; // User canceled the sign-in process
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
