import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      title: 'Risk Managment',
      color: Colors.black,
      theme: ThemeData(brightness: Brightness.dark),
      home: const MyHomePage(title: 'Risk Managment App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _Trade {
  _Trade(this.x, this.y);
  final int? x;
  final double? y;
}

class _MyHomePageState extends State<MyHomePage> with SignalsMixin {
  int ntrade = 0;
  List<_Trade> _generateTradeData() {
    return <_Trade>[_Trade(ntrade++, 0)];
  }

  late final _tradeData = createListSignal(_generateTradeData());
  final textMDController = TextEditingController();
  final textLTController = TextEditingController();
  final textATController = TextEditingController();
  final _textMDSignal = Signal<String>('');
  final _textLTSignal = Signal<String>('');
  final _textATSignal = Signal<String>('');

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        title: Text(widget.title),
      ),
      body: Center(
        heightFactor: double.maxFinite,
        widthFactor: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: SfCartesianChart(
                backgroundColor: Colors.black,
                trackballBehavior: TrackballBehavior(
                  enable: true,
                  tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
                  lineColor: Colors.grey,
                  markerSettings: TrackballMarkerSettings(
                    borderColor: Colors.amber,
                    borderWidth: 2.0,
                    color: Colors.black,
                    height: 2.0,
                    width: 2.0,
                    shape: DataMarkerType.circle,
                    markerVisibility: TrackballVisibilityMode.visible,
                  ),
                ),
                plotAreaBorderWidth: 1,
                primaryXAxis: const CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  labelPlacement: LabelPlacement.onTicks,
                ),
                primaryYAxis: const NumericAxis(
                  axisLine: AxisLine(width: 0),
                  enableAutoIntervalOnZooming: true,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  labelFormat: '{value}',
                  majorTickLines: MajorTickLines(size: 0),
                ),
                series: _buildTradeDataSeries(),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  canShowMarker: true,
                  color: Colors.black,
                  textStyle: TextStyle(color: Colors.white),
                  borderColor: Colors.grey,
                  header: "",
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(2, 6, 6, 6),
                  margin: EdgeInsets.only(bottom: 4),
                  height: 80.0,
                  width: screenWidth * 0.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.25,
                            height: 40,
                            child: IconButton(
                              tooltip: "Max Drowdown",
                              color: Colors.deepPurpleAccent,
                              icon: Icon(Icons.heart_broken),
                              onPressed: () => _displayTextInputDialog(
                                context,
                                'Max Drowdown',
                                'Put here max value',
                                textMDController,
                                _textMDSignal,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.25,
                            height: 40,
                            child: IconButton(
                              tooltip: "% loss/trade",
                              color: Colors.deepPurpleAccent,
                              icon: Icon(Icons.percent),
                              onPressed: () => _displayTextInputDialog(
                                context,
                                '% Loss Per Trade',
                                'Put % value here',
                                textLTController,
                                _textLTSignal,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.2,
                            height: 36,
                            child: Tooltip(
                              message: "Max Loss Per Trade",
                              child: Text(
                                '120',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade900,
                  child: SizedBox(
                    child: IconButton(
                      tooltip: "Add new trade",
                      color: Colors.deepPurpleAccent,
                      icon: Icon(Icons.add),
                      onPressed: () => _displayTextInputDialog(
                        context,
                        'Trade Result',
                        'Put result here',
                        textATController,
                        _textATSignal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<SplineSeries<_Trade, int>> _buildTradeDataSeries() {
    return [
      SplineSeries<_Trade, int>(
        enableTrackball: true,
        dataSource: _tradeData,
        xValueMapper: (_Trade data, int index) => data.x,
        yValueMapper: (_Trade data, int index) => data.y,
        markerSettings: const MarkerSettings(isVisible: true),
        color: Colors.deepPurpleAccent,
      ),
    ];
  }

  Future<void> _displayTextInputDialog(
    BuildContext context,
    String title,
    hint,
    TextEditingController tc,
    Signal ts,
  ) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: tc,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (title == 'Trade Result') {
                  var v = double.parse(tc.text);
                  _tradeData.add(_Trade(ntrade++, v));
                }
                ts.set(tc.text);
                debugPrint(ts.value);
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
