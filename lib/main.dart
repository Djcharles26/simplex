import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simplex/providers/SimplexProvider.dart';
import 'package:simplex/screens/entries.dart';
 
void main() => runApp(MyApp());
 
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simplex',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text('Simplex', style:TextStyle(fontSize: 28)),
        ),
        body: ChangeNotifierProvider.value(
          value: Simplex(),
          child: EntriesPage()
        )
      ),
    );
  }
}