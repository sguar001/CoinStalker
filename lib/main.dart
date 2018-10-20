import 'package:flutter/material.dart';

import 'coinapi.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final coinApi = new CoinApi();
    return new MaterialApp(
        title: 'CoinStalker',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: Text('Assets'),
            ),
            body: FutureBuilder<List<Asset>>(
                future: coinApi.listAllAssets(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return CircularProgressIndicator();

                    default:
                      if (snapshot.hasError) {
                        return new Text('${snapshot.error}');
                      }
                      else {
                        return createListView(context, snapshot);
                      }
                  }
                }
            )
        )
    );
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    List<Asset> values = snapshot.data;
    return new ListView.builder(
      itemCount: values.length,
      itemBuilder: (context, index) {
        return new Column(
            children: <Widget>[
              new ListTile(
                title: new Text(values[index].name),
              ),
              new Divider(height: 2.0),
            ]
        );
      }
    );
  }
}
