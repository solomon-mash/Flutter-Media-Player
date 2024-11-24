import 'package:flutter/material.dart';

class morepage extends StatefulWidget {
  const morepage({super.key});

  @override
  State<morepage> createState() => _morepageState();
}

class _morepageState extends State<morepage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Color(0xFF131313),
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              direction: Axis.vertical,
              alignment: WrapAlignment.center,
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 55),
                Text('Will be updated soon',
                    style: TextStyle(color: Colors.white))
              ],
            ),
          )
        ],
      ),
    ));
  }
}
