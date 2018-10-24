import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class login extends StatelessWidget{
  const login({
    Key key,
    @required this.onSubmit,
    } ): super(key:key);

  final VoidCallback onSubmit;
  static final TextEditingController _userinfo = new TextEditingController();
  static final TextEditingController _passinfo = new TextEditingController();

  String get username => _userinfo.text;
  String get pass => _passinfo.text;

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new TextField(controller: _userinfo, decoration: new InputDecoration(hintText: 'Enter in Username'),),
        new TextField(controller: _passinfo, decoration: new InputDecoration(hintText: 'Enter in Password'), obscureText: true,),
        new RaisedButton( child: new Text('Submit'), onPressed: onSubmit)

    ],
    );

  }
}


