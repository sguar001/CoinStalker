import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:validate/validate.dart';

import 'dashboard.dart';
import 'modal_progress.dart';

/// Widget for signing in or registering with an email account
/// This class is stateful because the interface contains a form which can
/// be in one of two states
class EmailSignInPage extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _EmailSignInPageState();
}

typedef Future<FirebaseUser> _Attempt();

/// Possible states for the form to occupy
enum _FormType {
  /// Fields and methods for registering a new account
  register,

  /// Fields and methods for signing in to an existing account
  signIn,
}

/// Maps a form type to a string suitable for use as a title
String _formTypeTitle(_FormType type) {
  switch (type) {
    case _FormType.register:
      return 'Register';
    case _FormType.signIn:
      return 'Sign in';
    default:
      return null;
  }
}

/// State for the email sign in page
class _EmailSignInPageState extends State<EmailSignInPage> {
  /// Instance of the Firebase authentication library
  final _auth = FirebaseAuth.instance;

  /// Key for the entire credentials form
  final _formKey = GlobalKey<FormState>();

  /// Key specifically for the registration password field
  /// This is used to verify that the two passwords provided are the same
  final _passwordKey = GlobalKey<FormFieldState<String>>();

  /// Validated email address provided by the user
  String _email;

  /// Validated password provided by the user
  String _password;

  /// Current state of the form
  /// The form can be used for both signing in and registering
  _FormType _formType = _FormType.signIn;

  /// Future for the operation that must complete before continuing is possible
  Future _blockingOperation;

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
        body: buildModalCircularProgressStack(
          future: _blockingOperation,
          child: SingleChildScrollView(
            child: Center(
              child: FractionallySizedBox(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildForm(),
                  ),
                ),
                widthFactor: 0.66,
              ),
            ),
          ),
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text('${_formTypeTitle(_formType)} with email'),
        ),
      );

  /// Builds child widgets list for the form appropriate for its type
  List<Widget> _buildForm() {
    switch (_formType) {
      case _FormType.register:
        return _buildRegisterForm();
      case _FormType.signIn:
        return _buildSignInForm();
      default:
        return [];
    }
  }

  /// Builds a child widgets list for a registration form
  List<Widget> _buildRegisterForm() => [
        _buildField(
          child: TextFormField(
            decoration: InputDecoration(labelText: 'Email address'),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            onSaved: (value) => _email = value,
          ),
        ),
        _buildField(
          child: TextFormField(
            key: _passwordKey,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: _validatePassword,
            onSaved: (value) => _password = value,
          ),
        ),
        _buildField(
          child: TextFormField(
            decoration: InputDecoration(labelText: 'Confirm password'),
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
        ),
        RaisedButton(
          key: Key('register'),
          child: Text('Register'),
          onPressed: () => _makeAttempt(_attemptRegister),
          color: Colors.green,
          textColor: Colors.white,
        ),
        FlatButton(
          key: Key('have-account'),
          child: Text('Have an account? Sign in'),
          onPressed: () => _setFormType(_FormType.signIn),
        ),
      ];

  /// Builds a child widgets list for a sign-in form
  List<Widget> _buildSignInForm() => [
        _buildField(
          child: TextFormField(
            decoration: InputDecoration(labelText: 'Email address'),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            onSaved: (value) => _email = value,
          ),
        ),
        _buildField(
          child: TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: _validatePassword,
            onSaved: (value) => _password = value,
          ),
        ),
        RaisedButton(
          key: Key('signin'),
          child: Text('Sign In'),
          onPressed: () => _makeAttempt(_attemptSignIn),
          color: Colors.green,
          textColor: Colors.white,
        ),
        FlatButton(
          key: Key('need-account'),
          child: Text('Need an account? Register'),
          onPressed: () => _setFormType(_FormType.register),
        ),
      ];

  /// Builds a containing widget for displaying a form field
  Widget _buildField(
          {Widget child,
          EdgeInsets padding = const EdgeInsets.only(bottom: 8.0)}) =>
      Padding(padding: padding, child: child);

  /// Sets the type of the form and causes a state change
  /// This also clears the form
  void _setFormType(_FormType type) {
    setState(() {
      _formKey.currentState.reset();
      _formType = type;
    });
  }

  /// Sets the blocking operation and causes a state change
  void _setBlockingOperation(Future blockingOperation) async =>
      setState(() => _blockingOperation = blockingOperation);

  /// Validates an email string
  /// Returns a string describing the failure condition, or null when valid
  String _validateEmail(String value) {
    if (value.isEmpty) return 'Required';
    try {
      Validate.isEmail(value);
    } catch (_) {
      return 'Must be an email address';
    }
    return null;
  }

  /// Validates a password string
  /// Returns a string describing the failure condition, or null when valid
  String _validatePassword(String value) => value.isEmpty ? 'Required' : null;

  /// Validates a confirm password string
  /// Returns a string describing the failure condition, or null when valid
  String _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'Required';
    if (value != _passwordKey.currentState.value) return 'Must match password';
    return null;
  }

  /// Validates the form and saving its state when valid
  bool _validate() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  /// Makes a submission attempt
  /// Sets the blocking operation to the result of the sign in method, waits for
  /// the method to complete successfully, then navigates to the dashboard
  void _makeAttempt(_Attempt attempt) async {
    // Only make an attempt when the form validates
    if (!_validate()) return;

    try {
      _setBlockingOperation(attempt().then((user) {
        if (user != null) {
          // Clear the stack by popping all routes below the sign-in page
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
              (_) => false);
        }
      }).catchError((e) => print(e))); // TODO: Better error reporting
    } catch (e) {
      print(e);
    }
  }

  /// Attempts to register a new account
  Future<FirebaseUser> _attemptRegister() async =>
      await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

  /// Attempts to sign in to an existing account
  Future<FirebaseUser> _attemptSignIn() async =>
      await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
}
