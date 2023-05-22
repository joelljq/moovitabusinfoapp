import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SurveyPage extends StatefulWidget {
  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[400],
        centerTitle: true,
        title: Text('Moovita Survey'),
      ),
      body: WebView(
        initialUrl:
            'https://docs.google.com/forms/d/e/1FAIpQLSdlTE_JtQPo2jVVGeI5LcjGcZKRggPlkuqBJWeZJVFgE27m4Q/viewform',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
