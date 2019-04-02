import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'email_signin.dart';
import 'modal_progress.dart';
import 'splash.dart';

/// Widget for selecting a method to sign in through
/// This class is stateful because the interface must wait while signing in is
/// attempted
class SignInPage extends StatefulWidget {
  /// Future for the operation that must complete before sign-in is possible
  /// This is typically a void future from FirebaseAuth.signOut
  final Future initialOperation;

  /// Constructs this widget instance
  SignInPage({this.initialOperation});

  /// Creates the mutable state for this widget
  @override
  createState() => _SignInPageState();
}

/// Type of function for sign-in attempts
typedef Future<FirebaseUser> _Attempt();

/// State for the sign in page
class _SignInPageState extends State<SignInPage> {
  /// Instance of the Firebase authentication library
  final _auth = FirebaseAuth.instance;

  /// Instance of the Google sign in system
  final _googleSignIn = GoogleSignIn();

  /// Future for the operation that must complete before sign-in is possible
  Future _blockingOperation;

  /// Called when this object is inserted into the tree
  @override
  void initState() {
    super.initState();

    // Begin by blocking on the initial operation from the widget
    _blockingOperation = widget.initialOperation;
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
        body: buildModalCircularProgressStack(
          future: _blockingOperation,
          child: Center(
            child: IntrinsicWidth(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGoogleButton(),
//                  _buildFacebookButton(),
//                  _buildTwitterButton(),
                  _buildEmailButton(),
                ],
              ),
            ),
          ),
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text('Sign in to CoinStalker'),
        ),
      );

  /// Makes a sign in attempt
  /// Sets the blocking operation to the result of the sign in method, waits for
  /// the method to complete successfully, then navigates to the dashboard
  void _makeAttempt(_Attempt attempt) async {
    setState(() {
      _blockingOperation = attempt()
          .then((user) => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => SplashPage())))
          .catchError((e) => print(e)); // TODO: Better error reporting
    });
  }

  /// Attempts to sign in via Google
  Future<FirebaseUser> _attemptGoogleSignIn() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser.authentication;
    return await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  /// Navigates to the email sign in page
  void _goToEmailSignIn() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => EmailSignInPage()));
  }

  /// Builds a button for signing in with Google
  Widget _buildGoogleButton() => _buildButton(
        method: 'Google',
        imageUri: 'images/google.png',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[700],
        onPressed: () => _makeAttempt(_attemptGoogleSignIn),
      );

  /// Builds a button for signing in with Facebook
  Widget _buildFacebookButton() => _buildButton(
        method: 'Facebook',
        imageUri: 'images/facebook.png',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[700],
        onPressed: () {}, // TODO
      );

  /// Builds a button for signing in with Twitter
  Widget _buildTwitterButton() => _buildButton(
        method: 'Twitter',
        imageUri: 'images/twitter.png',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[700],
        onPressed: () {}, // TODO
      );

  /// Builds a button for signing in with email
  Widget _buildEmailButton() => _buildButton(
        method: 'email',
        imageUri: 'images/email.png',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[700],
        onPressed: _goToEmailSignIn,
      );

  /// Builds a button that matches Google's sign-in branding guidelines
  /// See: https://developers.google.com/identity/branding-guidelines
  Widget _buildButton(
          {String method,
          String imageUri,
          Color backgroundColor,
          Color foregroundColor,
          VoidCallback onPressed}) =>
      RaisedButton(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              imageUri,
              width: 18.0,
              height: 18.0,
            ),
            SizedBox(width: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Sign in with $method',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
        onPressed: onPressed,
      );
}
