import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:lotto_app/models/lotto_types.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter & Python Example',
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const SelectionPage(),
    );
  }
}

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotto')),
      body: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Select which one you want to use: "),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const OptionPanel(lottoType: LottoTypes.lmax),
                    ),
                  );
                },
                child: const Text("Lotto MAX"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const OptionPanel(lottoType: LottoTypes.l649),
                    ),
                  );
                },
                child: const Text("Lotto 6/49"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionPanel extends StatefulWidget {
  const OptionPanel({super.key, required this.lottoType});

  final LottoTypes lottoType;

  @override
  State<OptionPanel> createState() => _OptionPanelState();
}

class _OptionPanelState extends State<OptionPanel> {
  String? _fileName;
  List<Map<String, dynamic>> _parsedData = [];

  String getTitle() {
    switch (widget.lottoType) {
      case LottoTypes.lmax:
        return "Lotto MAX";
      case LottoTypes.l649:
        return "Lotto 6/49";
      default:
        return "Undefined";
    }
  }

  String getSiteUrl() {
    switch (widget.lottoType) {
      case LottoTypes.lmax:
        return "https://www.getmylottoresults.com/lotto-max-past-winning-numbers/";
      case LottoTypes.l649:
        return "https://www.getmylottoresults.com/lotto-649-past-winning-numbers/";
      default:
        return "Undefined";
    }
  }

  Future<void> pickTextFile() async {
    // Open file picker to pick a text file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'], // Restrict to text files only
      allowMultiple: false,
    );

    if (result != null) {
      // Get the selected file
      File file = File(result.files.single.path!);

      // Read the file as a string
      String content = await file.readAsString();

      // Get the file name from the file's path
      String fileName = path.basename(file.path);

      // Store the raw content for debugging or display
      setState(() {
        _fileName = fileName;
      });

      // Parse the content
      _parseData(content);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  void _parseData(String content) {
    // Split the data into lines
    List<String> lines = content.split('\n');

    int partsCount;

    switch (widget.lottoType) {
      case LottoTypes.lmax:
        partsCount = 10;
        break;
      case LottoTypes.l649:
        partsCount = 9;
        break;
      default:
        throw Exception(
            "Undefined parts count for LottoType ${widget.lottoType}.");
    }

    // Parse each line
    List<Map<String, dynamic>> parsedData = lines
        .map((line) {
          // Split the line into parts by spaces
          List<String> parts = line.split(RegExp(r'\s+'));

          // Check if line has enough parts to be valid (date + 7 numbers)
          if (parts.length < partsCount) return null;

          // Extract the date (first 3 parts) and numbers (remaining parts)
          String date =
              "${parts[0]} ${parts[1]} ${parts[2]}"; // E.g., "15th October 2024"
          List<int> numbers = parts
              .sublist(3)
              .map((e) => int.tryParse(e) ?? 0)
              .toList(); // Convert remaining parts to numbers

          return {
            'date': date,
            'numbers': numbers,
          };
        })
        .where((item) => item != null)
        .toList()
        .cast<Map<String, dynamic>>();

    // Update the state with the parsed data
    setState(() {
      _parsedData = parsedData;
    });
  }

  List<int> _generateRandomCombination() {
    List<int> combination = [];

    int loopCount = 0;

    switch (widget.lottoType) {
      case LottoTypes.lmax:
        while (loopCount < 1000) {
          combination.clear();
          for (int i = 0; i < 7; i++) {
            int rand = 0;
            int nlc = 0; // new loop count
            while (nlc < 1000) {
              rand = _getRandomIntInRange(1, 49);
              if (combination.contains(rand)) {
                nlc++;
              } else {
                break;
              }
            }

            if (nlc >= 1000) {
              throw Exception("New loop count exceded boundary value.");
            }

            combination.add(rand);
          }
          combination.sort();
          if (_isExistingCombination(combination)) {
            loopCount++;
          } else {
            break;
          }
        }
        break;
      case LottoTypes.l649:
        while (loopCount < 1000) {
          combination.clear();
          for (int i = 0; i < 6; i++) {
            int rand = 0;
            int nlc = 0; // new loop count
            while (nlc < 1000) {
              rand = _getRandomIntInRange(1, 49);
              if (combination.contains(rand)) {
                nlc++;
              } else {
                break;
              }
            }

            if (nlc >= 1000) {
              throw Exception("New loop count exceded boundary value.");
            }

            combination.add(rand);
          }
          combination.sort();
          if (_isExistingCombination(combination)) {
            loopCount++;
          } else {
            break;
          }
        }
        break;
    }

    if (loopCount >= 1000) {
      throw Exception("Loop count exceded boundary value.");
    }

    return combination;
  }

  List<int> _generateWarmCombination() {
    int rangeMin, rangeMax, combLength;

    switch (widget.lottoType) {
      case LottoTypes.lmax:
        rangeMin = 1;
        rangeMax = 50;
        combLength = 7;
        break;
      case LottoTypes.l649:
        rangeMin = 1;
        rangeMax = 49;
        combLength = 6;
        break;
      default:
        throw Exception("Undefined range for LottoType ${widget.lottoType}.");
    }

    List<Map<String, int>> repeats = [];

    for (var i = rangeMin; i <= rangeMax; i++) {
      repeats.add({'number': i, 'count': 0});
    }

    for (var map in _parsedData) {
      final list = map['numbers'] as List<int>;
      for (var i = 0; i < combLength; i++) {
        final num = list[i];

        final index =
            repeats.indexOf(repeats.firstWhere((e) => e['number'] == num));
        final count = repeats[index]['count']!;
        repeats[index]['count'] = count + 1;
      }
    }

    repeats.sort((a, b) => b['count']!.compareTo(a['count']!));

    List<int> warmComb = [];

    for (var i = 0; i < combLength; i++) {
      warmComb.add(repeats[i]['number']!);
    }

    warmComb.sort();

    return warmComb;
  }

  int _getRandomIntInRange(int min, int max) {
    final random = Random(); // Create a Random instance

    // Generates a random integer between min (inclusive) and max (inclusive)
    return min + random.nextInt(max - min + 1);
  }

  bool _isExistingCombination(List<int> comb) {
    var checks = _parsedData;

    for (var i = 0; i < comb.length; i++) {
      List<Map<String, dynamic>> passed = [];

      for (var map in checks) {
        final list = map['numbers'] as List<int>;

        if (comb[i] == list[i]) {
          passed.add(map);
        }
      }

      if (passed.isNotEmpty) {
        checks = passed;
      } else {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getTitle())),
      body: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Select option: "),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _launchUrl(getSiteUrl());
                },
                child: const Text("Open site"),
              ),
            ),
            // Data file
            Visibility(
              visible: _fileName == null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    pickTextFile();
                  },
                  child: const Text("Pick data file"),
                ),
              ),
            ),
            Visibility(
              visible: _fileName != null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Picked file: $_fileName"),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _fileName = null;
                          _parsedData.clear();
                        });
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _parsedData.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CombinationPage(
                              combination: _generateRandomCombination(),
                            ),
                          ),
                        );
                      },
                child: const Text("Generate Random"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _parsedData.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CombinationPage(
                              combination: _generateWarmCombination(),
                            ),
                          ),
                        );
                      },
                child: const Text("Generate Warm"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CombinationPage extends StatelessWidget {
  const CombinationPage({super.key, required this.combination});

  final List<int> combination;

  List<Widget> getRow(BuildContext context) {
    List<Widget> children = [];

    for (var num in combination) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ColoredBox(
            color: Theme.of(context).primaryColor,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  "$num",
                  style: Theme.of(context).primaryTextTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Combination")),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: getRow(context),
        ),
      ),
    );
  }
}

class DataFetcher extends StatefulWidget {
  const DataFetcher({super.key});

  @override
  State<DataFetcher> createState() => _DataFetcherState();
}

class _DataFetcherState extends State<DataFetcher> {
  String message = "Waiting for data...";

  Future<void> fetchData() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/greet');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        message = data['message'];
      });
    } else {
      setState(() {
        message = 'Field to fetch data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        ElevatedButton(
          onPressed: fetchData,
          child: const Text('Fetch Data from Python Backend'),
        )
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
