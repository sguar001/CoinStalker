import 'package:flutter/material.dart';

import 'drawer.dart';

/// Widget for displaying the dashboard overview
/// This class is stateful because contains multiple tabs
class DashboardPage extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _DashboardPageState();
}

/// State for the dashboard page
class _DashboardPageState extends State<DashboardPage> {
  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
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
              title: Text('Graph'),
              icon: Icon(Icons.assessment),
            ),
            BottomNavigationBarItem(
              title: Text('List'),
              icon: Icon(Icons.list),
            ),
            BottomNavigationBarItem(
              title: Text('News'),
              icon: Icon(Icons.book),
            ),
          ],
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text('Dashboard'),
        ),
        drawer: UserDrawer(),
      );
}
