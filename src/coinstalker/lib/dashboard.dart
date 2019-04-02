import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'currency_details.dart';
import 'dashboard_coins.dart';
import 'dashboard_news.dart';
import 'drawer.dart';
import 'session.dart';

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

  /// Current tab for the navigation bar
  int _currentTab = 0;

  /// Children of the navigation bar
  final List<Widget> _children = [
    DashboardCoins(),
    DashboardNews(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    /// Use the WidgetsBindingObserver to listen to the status of the widget when
    /// it resumes or pauses. Allows us to see the dynamic link even if we don't execute
    /// initState again.
    _retrieveDynamicLink();
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
        body: _children[_currentTab],
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) => setState(() {
                _currentTab = index;
              }),
          currentIndex: _currentTab,
          items: [
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
