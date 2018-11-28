import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cryptocompare.dart';
import 'either.dart';

/// Widget for displaying the latest news on the dashboard
class DashboardNews extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _DashboardNewsState();
}

/// State for the dashboard coins widget
class _DashboardNewsState extends State<DashboardNews> {
  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Cache of fetched trading information
  News _news;

  // Live data
  bool _isLoading = true;

  /// Initializes the widget state
  @override
  void initState() {
    super.initState();

    refresh();
  }

  /// Refreshes the live data
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });
    final futures = <Future>[
      _cryptoCompare.latestNews(language: 'EN'),
    ];
    return Future.wait(futures).then((responses) {
      setState(() {
        _news = responses[0];
        _isLoading = false;
      });
    });
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => CircularProgressFallbackBuilder(
        isFallback: _isLoading,
        builder: (context) => RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                itemCount: _news.data.length,
                itemBuilder: (context, index) => DashboardNewsTile(
                      article: _news.data[index],
                    ),
              ),
            ),
      );
}

class DashboardNewsTile extends StatefulWidget {
  final NewsArticle article;

  DashboardNewsTile({@required this.article});

  @override
  createState() => _DashboardNewsTileState();
}

class _DashboardNewsTileState extends State<DashboardNewsTile> {
  final _unescape = HtmlUnescape();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                  child: Text('${_unescape.convert(widget.article.title)}')),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_unescape.convert(widget.article.body)}\n'),
                  Text('Published: ${widget.article.publishedOn}'),
                  Text('Source: ${_unescape.convert(widget.article.source)}'),
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.open_in_browser),
                      color: Colors.green,
                      onPressed: () {
                        launch(widget.article.url);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
