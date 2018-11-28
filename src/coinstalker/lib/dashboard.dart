import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:http/http.dart' as http;

import 'drawer.dart';
import 'session.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'dart:async';
import 'dart:convert';


/// Widget for displaying the dashboard overview
/// This class is stateful because contains multiple tabs
class DashboardPage extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _DashboardPageState();
}

/// State for the dashboard page
class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  /// Instance of the application session
  final _session = Session();

  //Current tab for the navigation bar.
  int currentTab = 0;
  GraphPage _graphPage;
  FavoritePage _favoritesPage;
  NewsPage _newsPage;
  List<Widget> pages;
  Widget currentPage;

  //Url to get data from
  final String url = 'https://min-api.cryptocompare.com/data/v2/news/?lang=EN';

  //Variable to store data in
  List data;

  Future<String> getNewsData() async {
    var res = await http
        .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});

    setState(() {
      var resBody = json.decode(res.body);
      data = resBody["Data"];
    });

    return "Success!";
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// Each time the dashboard is resumed(app is opened again),
    /// the method is invoked to obtain the dynamic link
    if (state == AppLifecycleState.resumed) {
      _retrieveDynamicLink();
    }
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
        body: currentPage,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (int index) {
            setState(() {
              currentTab = index;
              if (index == 0)
                currentPage = _buildGraph(context);
              else if (index == 1) {
                currentPage = pages[1];
              }
              else if (index == 2) {
                currentPage = _buildAllNews(context);
              }
              else {
                index = index % 3;
              }
            });
          },
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text('Graph'),
              icon: Icon(Icons.assessment),
            ),
            BottomNavigationBarItem(
              title: Text('Favorites'),
              icon: Icon(Icons.favorite),
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

  Widget _buildGraph(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildAllNews(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: data == null ? 0 : data.length,
        itemBuilder: (BuildContext context, int index) {
          return new Container(
              child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Card(
                        child: Container(
                          color: Colors.blue,
                          padding: EdgeInsets.all(15.0),
                          child: Text("Title: " + data[index]["title"],
                              style:
                              TextStyle(fontSize: 18.0,
                                  color: Colors.black54
                              )),
                        ),
                      ),
                      Card(
                          child: Container(
                            padding: EdgeInsets.all(15.0),
                            child: Text("About: " + data[index]["body"],
                                style:
                                TextStyle(fontSize: 18.0,
                                    color: Colors.black54
                                )),
                          )
                      ),],
                  )
              )
          );
        },
      ),
    );
  }

  @override
  void initState() {
    _graphPage = GraphPage();
    _favoritesPage = FavoritePage();
    _newsPage = NewsPage();
    pages = [_graphPage, _favoritesPage, _newsPage];

    currentPage = _buildGraph(context);
    super.initState();
    this.getNewsData();

    /// Use the WidgetsBindingObserver to listen to the status of the widget when
    /// it resumes or pauses. Allows us to see the dynamic link even if we don't execute
    /// initState again.
    WidgetsBinding.instance.addObserver(this);
    _retrieveDynamicLink();
  }

  ///  calls the method that is responsible for obtaining the deep link
  ///  in the case our application was opened from the deep link
  ///  ASSUMING that we start the app for the first time and we hit the initState()
  Future<void> _retrieveDynamicLink() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      print('DeepLink: $deepLink');

      /// Grab the url link specified in dynamic link
      var urlPath = deepLink.pathSegments[0];

      /// dynamic link is pointing to currency detail page
      if (urlPath == 'coin') {
        /// if the link leads to a coin, grab it's provided coin ID
        var coinID = deepLink.pathSegments[1];

        /// filter criteria to be used when seaching the list of coins
        /// Here, it returns true when the coins id matches specified id
        final _filter = (Coin coin) => coin.id.toString() == coinID;

        /// Grab the coin from list of coins, where the passed in id matches
        Coin coinFromID = _session.coins.singleWhere(_filter);

        /// Change navigator route to the route specified in deep link that was retrieved
        /// Here, it is the currency detail page, to the specified coin
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (_) => CurrencyDetailsPage(coin: coinFromID)));
      }
    } else {
      print('Deeplink: $deepLink');
    }
  }

  @override
  void dispose() {
    /// Get rid of the observer once we are done using it
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class GraphPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashboardPageState()._buildGraph(context);
  }
}

class FavoritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      //TODO: Add favoritePage
      height:300.0,
      color: Colors.blue,
    );
  }
}

class NewsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashboardPageState()._buildAllNews(context);
  }
}
