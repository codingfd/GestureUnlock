// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'gesture_create.dart';
import 'gesture_verify.dart';


void main() => runApp(MyApp());



// #docregion MyApp
class MyApp extends StatelessWidget {
  // #docregion build
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      home: ListWidget(),
    );
  }

// #enddocregion build
}
// #enddocregion MyApp

// #docregion RWS-var
class ListWidgetState extends State<ListWidget> {
  final _suggestions = <String>["创建手势","验证手势"];
  final _biggerFont = const TextStyle(fontSize: 18.0);

  // #enddocregion RWS-var

  // #docregion _buildSuggestions
  Widget _buildSuggestions() {
    return ListView.builder(
        itemCount: _suggestions.length * 2,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider();
          /*2*/

          final index = i ~/ 2; /*3*/

          return _buildRow(_suggestions[index],index);
        });
  }

  // #enddocregion _buildSuggestions

  // #docregion _buildRow
  Widget _buildRow(String content,int pos) {
    return ListTile(
      title: Text(
        content,
        style: _biggerFont,
      ),
      onTap: (){
        switch(pos){

          case 0:{
            Navigator.of(context).push(MaterialPageRoute(builder: (context)=> GestureCreatePage()));
            break;
          }
          case 1:{
            Navigator.of(context).push(MaterialPageRoute(builder: (context)=> GestureVerifyPage()));

          }
        }
      },
    );
  }

  // #enddocregion _buildRow

  // #docregion RWS-build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("手势"),
      ),
      body: _buildSuggestions(),
    );
  }

}

class ListWidget extends StatefulWidget {
  @override
  ListWidgetState createState() => ListWidgetState();
}
