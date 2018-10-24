import 'package:flutter/material.dart';
import 'package:flutter_app/placeholder.dart';
import 'package:flutter_app/login.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget{
  _MyAppState createState() => new _MyAppState();

}

class _MyAppState extends State<MyApp> {

  String _title = 'Login Please';
  Widget _screen;
  login _testlogin;
  settings _testsetting;
  bool _authenticated;


  _MyAppState(){
   _testlogin = new login(onSubmit: (){onSubmit();});
   _testsetting = new settings();
   _screen = _testlogin;
   _authenticated = false;

  }


  /*TODO: Here is where we would need to integrate Firebase.
   Here are some resources: https://www.youtube.com/watch?v=DqJ_KjFzL9I
   https://codelabs.developers.google.com/codelabs/flutter-firebase/#0
   */
  void onSubmit(){
    print('Please Login: ' + _testlogin.username + ' ' + _testlogin.pass);
    if(_testlogin.username == 'user' && _testlogin.pass == 'password'){
      _setAuth(true);
    }
  }

  void _homeButton(){
    print('Now returning home $_authenticated');
    setState(() {
      if( _authenticated == true){
        _screen = _testsetting;
        _title = 'Welcome';
      }
      else{
        _screen = _testlogin;

      }

    });

  }

  void _logoutButton(){
    print('Now logging off');
    _setAuth(false);
  }

  void _setAuth(bool authTest){
    setState(() {
      if( authTest == true){
        _screen = _testsetting;
        _title = 'Welcome';
        _authenticated = true;
      }
      else{
        _screen = _testlogin;
        _title  = 'Please login';
        _authenticated = false;

      }

    });
  }


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Login Demo',
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text(_title),
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.home), onPressed: (){_homeButton();}),
            new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: (){_logoutButton();} ),
          ],
        ),
        body: _screen,
      )
    );
  }


}
