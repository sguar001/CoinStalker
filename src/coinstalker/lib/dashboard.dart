import 'package:flutter/material.dart';
import 'currency_list.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  Color gradientEnd = Colors.black;
  Color gradientStart = Colors.lightGreenAccent;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(
//        backgroundColor: new Color(0xFFFF9000),
//        title: Text('CoinStalker'),
//      )

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.1, 0.5, 0.7, 0.9],
            colors: [
              Colors.black,
              Colors.green[700],
              Colors.green[600],
              Colors.black,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Image.asset(
                        'images/stock.jpg',
                        height: 300.0,
                        //width: 350.0,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.assessment),
            title: new Text('graph'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.info),
            title: new Text('Info'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.book),
            title: new Text('News'),
          ),
        ],
        //fixedColor: Colors.grey
      ),

      appBar: AppBar(
        title: Text('CoinStalker'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Options'),
              decoration: BoxDecoration(
                color: Colors.green,
              ),
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Search'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CurrencyList()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
