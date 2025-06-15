import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../view_model/risk_management_view_model.dart';

class TradeChartWidget extends StatefulWidget {
  final RiskManagementViewModel viewModel;

  const TradeChartWidget({super.key, required this.viewModel});

  @override
  State<TradeChartWidget> createState() => _TradeChartWidgetState();
}

class _TradeChartWidgetState extends State<TradeChartWidget> with SignalsMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Watch((_) {
        final chartData = widget.viewModel.chartData;

        return SfCartesianChart(
          backgroundColor: Colors.black,
          title: ChartTitle(
            text: 'Trading Performance',
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          trackballBehavior: TrackballBehavior(
            enable: true,
            tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
            lineColor: Colors.grey,
            markerSettings: const TrackballMarkerSettings(
              borderColor: Colors.amber,
              borderWidth: 2.0,
              color: Colors.black,
              height: 8.0,
              width: 8.0,
              shape: DataMarkerType.circle,
              markerVisibility: TrackballVisibilityMode.visible,
            ),
          ),
          plotAreaBorderWidth: 1,
          plotAreaBorderColor: Colors.grey.shade800,
          primaryXAxis: const NumericAxis(
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: Colors.grey,
              dashArray: [2, 2],
            ),
            interval: 1,
            minimum: 0,
            title: AxisTitle(
              text: 'Trade Number (0 = Starting Point)',
              textStyle: TextStyle(color: Colors.white70),
            ),
            labelStyle: TextStyle(color: Colors.white70),
            axisLine: AxisLine(color: Colors.grey),
          ),
          primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 1, color: Colors.grey),
            enableAutoIntervalOnZooming: true,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            labelFormat: '\${value}',
            majorTickLines: const MajorTickLines(size: 0),
            majorGridLines: const MajorGridLines(
              width: 0.5,
              color: Colors.grey,
              dashArray: [2, 2],
            ),

            title: const AxisTitle(
              text: 'Cumulative P&L',
              textStyle: TextStyle(color: Colors.white70),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            plotBands: _buildPlotBands(),
          ),
          series: _buildTradeDataSeries(chartData),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            canShowMarker: true,
            color: Colors.grey.shade900,
            textStyle: const TextStyle(color: Colors.white),
            borderColor: Colors.deepPurpleAccent,
            borderWidth: 1,
            header: 'Trade Details',
            format: 'Trade point.x: point.y',
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true,
            enablePanning: true,
            enableDoubleTapZooming: true,
            zoomMode: ZoomMode.x,
          ),
        );
      }),
    );
  }

  List<PlotBand> _buildPlotBands() {
    return [
      // Break-even line
      PlotBand(
        start: 0,
        end: 0,
        borderColor: Colors.white,
        borderWidth: 1,
        dashArray: const [5, 5],
        text: 'Break Even',
        textStyle: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    ];
  }

  List<SplineSeries<ChartData, int>> _buildTradeDataSeries(
    List<ChartData> data,
  ) {
    return [
      SplineSeries<ChartData, int>(
        name: 'P&L',
        enableTrackball: true,
        dataSource: data,
        xValueMapper: (ChartData data, int index) => data.x,
        yValueMapper: (ChartData data, int index) => data.y,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
          borderColor: Colors.deepPurpleAccent,
          borderWidth: 2,
          color: Colors.black,
        ),
        color: Colors.deepPurpleAccent,
        width: 2,
        splineType: SplineType.natural,
        cardinalSplineTension: 0.5,
        dataLabelSettings: data.length <= 20
            ? const DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.auto,
                textStyle: TextStyle(color: Colors.white70, fontSize: 10),
                labelIntersectAction: LabelIntersectAction.hide,
              )
            : const DataLabelSettings(isVisible: false),

        animationDuration: 1000,
      ),
    ];
  }
}
