import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'dart:math' as math;
import '../../view_model/risk_management_view_model.dart';

class TradeChartWidget extends StatefulWidget {
  final RiskManagementViewModel viewModel;

  const TradeChartWidget({super.key, required this.viewModel});

  @override
  State<TradeChartWidget> createState() => _TradeChartWidgetState();
}

class _TradeChartWidgetState extends State<TradeChartWidget> with SignalsMixin {
  late RangeController xRangeController;
  late RangeController yRangeController;

  @override
  void initState() {
    super.initState();
    xRangeController = RangeController(start: 0, end: 100);
    yRangeController = RangeController(start: -100, end: 100);
  }

  @override
  void dispose() {
    xRangeController.dispose();
    yRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
      child: Watch((_) {
        final chartData = widget.viewModel.chartData;
        final drawdownData = widget.viewModel.drawdownChartData;
        return Stack(
          children: [
            SfCartesianChart(
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
              primaryXAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.grey,
                  dashArray: [2, 2],
                ),
                interval: 1,
                axisLine: const AxisLine(color: Colors.grey),
                rangeController: xRangeController,
                minimum: 0,
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 1, color: Colors.grey),
                enableAutoIntervalOnZooming: true,
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.grey,
                  dashArray: [2, 2],
                ),
                plotBands: _buildPlotBands(),
                rangeController: yRangeController,
              ),
              series: _buildTradeDataSeries(chartData, drawdownData),
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
                zoomMode: ZoomMode.xy,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: _handleXZoom,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: _handleYZoom,
              ),
            ),
          ],
        );
      }),
    );
  }

  List<PlotBand> _buildPlotBands() {
    return [
      PlotBand(
        start: 0,
        end: 0,
        borderColor: Colors.white,
        borderWidth: 1,
        dashArray: const [5, 5],
      ),
    ];
  }

  double get minY {
    List<double> allY = [
      ...widget.viewModel.chartData.map((e) => e.y),
      ...widget.viewModel.drawdownChartData.map((e) => e.y)
    ];
    return allY.isEmpty ? 0 : allY.reduce(math.min);
  }

  double get maxY {
    List<double> allY = [
      ...widget.viewModel.chartData.map((e) => e.y),
      ...widget.viewModel.drawdownChartData.map((e) => e.y)
    ];
    return allY.isEmpty ? 1 : allY.reduce(math.max);
  }

  void _handleXZoom(DragUpdateDetails details) {
    double delta = details.delta.dx;
    double factor = 1 - (delta / 100);
    _adjustXZoom(factor);
  }

  void _handleYZoom(DragUpdateDetails details) {
    double delta = details.delta.dy;
    double factor = 1 + (delta / 100);
    _adjustYZoom(factor);
  }

  void _adjustXZoom(double factor) {
    double currentStart = (xRangeController.start).toDouble() ?? 0.0;
    double currentEnd = (xRangeController.end).toDouble() ??
        (widget.viewModel.chartData.isNotEmpty
            ? widget.viewModel.chartData.last.x.toDouble()
            : 1.0);
    double currentRange = currentEnd - currentStart;
    double newRange = (currentRange * factor).clamp(0.1, double.infinity);
    double center = (currentStart + currentEnd) / 2;
    double newStart = center - newRange / 2;
    double newEnd = center + newRange / 2;
    double dataMin = 0.0;
    double dataMax = widget.viewModel.chartData.isNotEmpty
        ? widget.viewModel.chartData.last.x.toDouble()
        : 1.0;
    newStart = newStart.clamp(dataMin, dataMax);
    newEnd = newEnd.clamp(newStart + 0.1, dataMax);
    setState(() {
      xRangeController.start = newStart;
      xRangeController.end = newEnd;
    });
  }

  void _adjustYZoom(double factor) {
    double currentStart = yRangeController.start as double? ?? minY;
    double currentEnd = yRangeController.end as double? ?? maxY;
    double currentRange = currentEnd - currentStart;
    double newRange = (currentRange * factor).clamp(0.1, double.infinity);
    double center = (currentStart + currentEnd) / 2;
    double newStart = center - newRange / 2;
    double newEnd = center + newRange / 2;
    if (newStart > newEnd) {
      double temp = newStart;
      newStart = newEnd;
      newEnd = temp;
    }
    setState(() {
      yRangeController.start = newStart;
      yRangeController.end = newEnd;
    });
  }

  List<SplineSeries<ChartData, int>> _buildTradeDataSeries(
    List<ChartData> pnlData,
    List<ChartData> ddData,
  ) {
    return [
      SplineSeries<ChartData, int>(
        name: 'P&L',
        enableTrackball: true,
        dataSource: pnlData,
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
        dataLabelSettings: pnlData.length <= 20
            ? const DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.auto,
                textStyle: TextStyle(color: Colors.white70, fontSize: 10),
                labelIntersectAction: LabelIntersectAction.hide,
              )
            : const DataLabelSettings(isVisible: false),
        animationDuration: 1000,
      ),
      SplineSeries<ChartData, int>(
        name: 'Drawdown',
        enableTrackball: true,
        dataSource: ddData,
        xValueMapper: (ChartData data, int index) => data.x,
        yValueMapper: (ChartData data, int index) => data.y,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
          borderColor: Colors.redAccent,
          borderWidth: 2,
          color: Colors.black,
        ),
        color: Colors.redAccent,
        width: 2,
        splineType: SplineType.natural,
        cardinalSplineTension: 0.5,
        dataLabelSettings: ddData.length <= 20
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