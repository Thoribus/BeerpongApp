import 'package:flutter/material.dart';

void main() {
  runApp(const BeerPongApp());
}

class BeerPongApp extends StatelessWidget {
  const BeerPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Beer Pong'),
        ),
        body: const BeerPongTable(),
      ),
    );
  }
}

class BeerPongTable extends StatefulWidget {
  const BeerPongTable({super.key});

  @override
  _BeerPongTableState createState() => _BeerPongTableState();
}

class _BeerPongTableState extends State<BeerPongTable> {
  List<Cup> cups = [];

  @override
  void initState() {
    super.initState();
    // Generate cups for the pyramid
    for (int row = 3; row >= 0; row--) {
      for (int col = 0; col <= row; col++) {
        cups.add(Cup(row * 4 + col));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int row = 3; row >= 0; row--)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col <= row; col++)
                  GestureDetector(
                    onTap: () {
                      print(row * (row + 1) ~/ 2 + col);
                      setState(() {
                        int cupIndex = row * (row + 1) ~/ 2 + col;
                        cups[cupIndex].isVisible = false;
                      });
                    },
                    child: cups[row * (row + 1) ~/ 2 + col].widget,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class Cup {
  final int index;
  bool isVisible;

  Cup(this.index) : isVisible = true;

  // Define a getter for the cup widget
  Widget get widget {
    return Visibility(
      visible: isVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        width: 50.0,
        height: 50.0,
        decoration: const BoxDecoration(
          color: Colors.red, // Cup color
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
