import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'alpha_chart_model.dart';

class AlphaChartWidget extends StatelessWidget {
  final List<ChartData> data;

  const AlphaChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(),
      series: <CandleSeries>[
        CandleSeries<ChartData, DateTime>(
          dataSource: data,
          xValueMapper: (ChartData d, _) => d.time,
          lowValueMapper: (ChartData d, _) => d.low,
          highValueMapper: (ChartData d, _) => d.high,
          openValueMapper: (ChartData d, _) => d.open,
          closeValueMapper: (ChartData d, _) => d.close,
        )
      ],
    );
  }
}
