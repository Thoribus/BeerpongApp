import 'package:flutter/material.dart';

void main() {
  runApp(const BeerPongApp());
}

class BeerPongApp extends StatelessWidget {
  const BeerPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.white, //  <-- dark color
          textTheme:
              ButtonTextTheme.primary, //  <-- this auto selects the right color
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Beerpong App'),
      //home: new Scaffold(
      //Here you can set what ever background color you need.
      //backgroundColor: Colors.black,
      //),
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

  _new_button_becher(int index) {
    return Visibility(
        child: FloatingActionButton.large(
            backgroundColor: const Color(0xFFFFFF), //schwarzer Hintergrund
            onPressed: _incrementCounter,
            tooltip: 'Becher ' + index.toString(),
            child: Icon(Icons.panorama_fish_eye_rounded,
                color: Colors.red, size: 90.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(45),
            )));
  }

  _new_button_airball(int index) {
    return Visibility(
        child: FloatingActionButton.extended(
            onPressed: () {},
            tooltip: 'Airball',
            label: Text('Airball'),
            icon: Icon(Icons.air_rounded)));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Colors.amber,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.start,

          children: <Widget>[
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_new_button_airball(10)]),
            SizedBox(height: 50),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _new_button_becher(6),
              _new_button_becher(7),
              _new_button_becher(8),
              _new_button_becher(9)
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _new_button_becher(3),
              _new_button_becher(4),
              _new_button_becher(5)
            ]),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_new_button_becher(1), _new_button_becher(2)]),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_new_button_becher(0)]),
            SizedBox(height: 50),
            const Text('So viele Becher habe ich getroffen:',
                style: TextStyle(color: Colors.white)),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
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

      //floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.scatter_plot_outlined),
            ),
            SizedBox(width: 10),
            FloatingActionButton.extended(
                onPressed: () {},
                tooltip: 'Kein Becher wurde diese Runde getroffen.',
                label: Text('Nix getroffen'),
                icon: Icon(Icons.clear_rounded)),
            Expanded(child: Container()),
            FloatingActionButton.extended(
                onPressed: () {},
                tooltip:
                    'Die getroffenen Becher wurden ausgewählt. Gegnerischer Zug.',
                label: Text('Zug beenden'),
                icon: Icon(Icons.check_rounded)),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      backgroundColor: Colors.black,
    );
  }
}
