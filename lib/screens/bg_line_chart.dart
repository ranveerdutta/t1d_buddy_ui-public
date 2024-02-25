import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/forms/user_log.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/timeline.dart';
import 'dart:math';

import 'package:t1d_buddy_ui/utils/common_utils.dart';

class _LineChart extends StatelessWidget {
  const _LineChart({required this.bgLogList, required this.startTime, required this.endTime, required this.timelineFilter, required this.userProfile});


  final List<UserLog> bgLogList;

  final DateTime startTime;

  final DateTime endTime;

  final TimelineFilter timelineFilter;

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      bgLogData,
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }

  LineChartData get bgLogData => LineChartData(
    lineTouchData: lineTouchData,
    gridData: gridData,
    titlesData: titlesData,
    borderData: borderData,
    lineBarsData: lineBarsData,
    extraLinesData: ExtraLinesData(horizontalLines: horizontalLines),
    minX: Utils.convertDateTimeToHourMin(startTime),
    maxX: Utils.convertDateTimeToHourMin(endTime),
    maxY: bgLogList.length > 0 ? (bgLogList.map((bgLog) => bgLog.bgValue).reduce(max) > userProfile.normalBgMax ? bgLogList.map((bgLog) => bgLog.bgValue).reduce(max) : userProfile.normalBgMax.toDouble()) : (userProfile.bgUnit == 'MMOL' ? 10 : 180),
    minY: 0,
  );


  List<HorizontalLine> get horizontalLines =>
      [
        HorizontalLine(
          y: userProfile.normalBgMin.toDouble(),
          color: Colors.white.withOpacity(0.8),
          strokeWidth: 3,
          dashArray: [2, 2],
          label: HorizontalLineLabel(show: true, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        HorizontalLine(
          y: userProfile.normalBgMax.toDouble(),
          color: Colors.white.withOpacity(0.8),
          strokeWidth: 3,
          dashArray: [2, 2],
          label: HorizontalLineLabel(show: true, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ];

  LineTouchData get lineTouchData => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: Colors.white.withOpacity(0.8),

        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final flSpot = barSpot;
            TextAlign textAlign;
            if(flSpot.x.toInt() == Utils.convertDateTimeToHourMin(startTime)) textAlign = TextAlign.left;
            else if(flSpot.x.toInt() == Utils.convertDateTimeToHourMin(endTime)) textAlign = TextAlign.right;
            else textAlign = TextAlign.center;

            return LineTooltipItem(
              flSpot.y.toString() + '\n',
              const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,

              ),
              children: [
                TextSpan(
                  text: 'at ' + Utils.convertMinutesToHhMmString(flSpot.x.toInt()),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
              textAlign: textAlign,
            );
          }).toList();
        }

    ),
  );

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: leftTitles(),
    ),
  );

  List<LineChartBarData> get lineBarsData => [
    lineChartBarData,
  ];



  Widget leftTitleWidgetsMgdl(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff72719b),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 60:
        text = '60';
        break;
      case 120:
        text = '120';
        break;
      case 180:
        text = '180';
        break;
      case 240:
        text = '240';
        break;
      case 300:
        text = '300';
        break;
      default:
        text = '';
    }

    return Padding(
      child: Text(text, style: style, textAlign: TextAlign.end),
      padding: const EdgeInsets.only(right: 6),
    );
  }

  Widget leftTitleWidgetsMmol(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 3:
        text = '3';
        break;
      case 6:
        text = '6';
        break;
      case 10:
        text = '9';
        break;
      case 12:
        text = '12';
        break;
      case 15:
        text = '15';
        break;
      default:
        text = '';
    }

    return Padding(
      child: Text(text, style: style, textAlign: TextAlign.end),
      padding: const EdgeInsets.only(right: 6),
    );
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: userProfile.bgUnit == 'MMOL' ? leftTitleWidgetsMmol : leftTitleWidgetsMgdl,
    showTitles: false,
    interval: userProfile.bgUnit == 'MMOL' ? 3 : 60,
    reservedSize: 10,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    String text;
    double first = Utils.convertDateTimeToHourMin(startTime);
    double second = Utils.convertDateTimeToHourMin(endTime);
    if(value.toDouble() == first) text = text = "";
    else if(value.toDouble() == second) text = "";
    else text = Utils.convertMinutesToHhMmStringTimeline(value.toInt());

    return Text(text, style: style, textAlign: TextAlign.center);

    /*return Padding(
      child: Text(text, style: style, textAlign: TextAlign.center),
      padding: const EdgeInsets.only(top: 5),
    );*/

  }

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    //reservedSize: 4,
    interval: this.timelineFilter == TimelineFilter.weekly ? 36 * 60 : 6 * 60,
    getTitlesWidget: bottomTitleWidgets,
  );

  FlGridData get gridData => FlGridData(show: true, );

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: const Border(
      bottom: BorderSide(color: Color(0xff4e4965), width: 4),
      left: BorderSide(color: Color(0xff4e4965), width: 4),
      right: BorderSide(color: Colors.transparent),
      top: BorderSide(color: Colors.transparent),
    ),
  );

  LineChartBarData get lineChartBarData => LineChartBarData(
    isCurved: false,
    color: Colors.red.withOpacity(1.0),
    barWidth: 2,
    isStrokeCapRound: true,
    dashArray: [4, 4],
    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(radius: 3, color: Colors.red)),
    belowBarData: BarAreaData(show: false),
    spots: bgLogList.map((point) => FlSpot(Utils.convertDateTimeToHourMin(point.logTime), point.bgValue)).toList(),
  );

}

class BgLineChart extends StatefulWidget {
  const BgLineChart(this._bgLogList, this._startTime, this._endTime, this._timelineFilter, this._userProfile, {Key? key})
      : super(key: key);

  final List<UserLog> _bgLogList;
  final DateTime _startTime;

  final DateTime _endTime;
  final UserProfile _userProfile;
  final TimelineFilter _timelineFilter;

  @override
  State<StatefulWidget> createState() => BgLineChartState();
}

class BgLineChartState extends State<BgLineChart> {

  late List<UserLog> _bgLogList;

  late DateTime _startTime;

  late DateTime _endTime;

  late UserProfile _userProfile;

  late TimelineFilter _timelineFilter;

  @override
  void initState() {
    super.initState();
    _bgLogList = widget._bgLogList;
    _startTime = widget._startTime;
    _endTime = widget._endTime;
    _userProfile = widget._userProfile;
    _timelineFilter = widget._timelineFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.23,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.blue,
              //Color(0xff46426c),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 37,
                ),
                Text(
                  'BG in ' + _userProfile.bgUnit!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 37,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 25.0, bottom: 25.0),
                    child: _LineChart(bgLogList: _bgLogList, startTime: _startTime, endTime: _endTime, timelineFilter: _timelineFilter, userProfile: _userProfile,),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
