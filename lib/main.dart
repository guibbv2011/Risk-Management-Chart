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
                              onPressed: () => _displayTextInputDialog(
                                context,
                                'Max Drowdown',
                                'Put here max value',
                                textMDController,
                                _textMDSignal,
                              ),
                              onPressed: () => _displayTextInputDialog(
                                context,
                                '% Loss Per Trade',
                                'Put % value here',
                                textLTController,
                                _textLTSignal,
                              ),
                      onPressed: () => _displayTextInputDialog(
                        context,
                        'Trade Result',
                        'Put result here',
                        textATController,
                        _textATSignal,
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => (),
        child: Icon(Icons.add),
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
