// GOLDEN BAD FIXTURE — deliberately violates the rules. Each validator must flag it.
import 'package:flutter/material.dart';

class BadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 12, right: 12),
        child: Column(children: [
          Container(color: Color(0xFFAB1234), padding: EdgeInsets.all(13)),
          Container(height: 20, child: Text('Title', textAlign: TextAlign.left)),
          GestureDetector(onTap: () {}, child: SizedBox(width: 30, height: 30)),
          Text('tiny', style: TextStyle(fontSize: 10)),
          Text('brand', style: TextStyle(color: Color(0xFF00FF00))),
        ]),
      ),
    );
  }
}
