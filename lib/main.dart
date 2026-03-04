import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'models/temple_lat_lng.dart';
import 'models/time_place.dart';

// ── カラー定数 ────────────────────────────────────────────
const Color _bgColor = Color(0xFF0D0D0D);
const Color _surfaceColor = Color(0xFF1A1A1A);
const Color _borderColor = Color(0xFF2E2E2E);
const Color _textColor = Color(0xFFE0E0E0);
const Color _sundayColor = Color(0xFFFF6B6B);
const Color _saturdayColor = Color(0xFF6B9EFF);
const Color _todayBorderColor = Color(0x99FFEE00); // 半透明の黄色

// 3桁カンマ区切り
String _formatPrice(int price) => price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カレンダー',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgColor,
        appBarTheme: const AppBarTheme(backgroundColor: _surfaceColor, foregroundColor: _textColor, elevation: 0),
      ),
      debugShowCheckedModeBanner: false,
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends HookWidget {
  const CalendarPage({super.key});

  static const List<String> _weekdayLabels = <String>['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    // ① useState: 表示中の年月を管理する
    final ValueNotifier<DateTime> displayMonth = useState(DateTime(now.year, now.month));

    // ② useMemoized: displayMonth が変わったときだけカレンダーの日付リストを再計算する
    final List<DateTime?> calendarDays = useMemoized(() {
      final int year = displayMonth.value.year;
      final int month = displayMonth.value.month;
      final DateTime firstDay = DateTime(year, month);
      final DateTime lastDay = DateTime(year, month + 1, 0);

      // DateTime.weekday: 月=1 … 日=7  → %7 で 日=0, 月=1 … 土=6
      final int leadingBlanks = firstDay.weekday % 7;

      final List<DateTime?> days = <DateTime?>[];
      for (int i = 0; i < leadingBlanks; i++) {
        days.add(null);
      }
      for (int d = 1; d <= lastDay.day; d++) {
        days.add(DateTime(year, month, d));
      }
      while (days.length % 7 != 0) {
        days.add(null);
      }
      return days;
    }, <Object?>[displayMonth.value]);

    // ③ useMemoized: API の Future を一度だけ生成する（再レンダリングで再生成しない）
    final Future<Map<String, List<TimePlace>>> timePlaceFuture = useMemoized(fetchTimePlaceMap);
    final Future<Map<String, TempleLatLng>> templeLatLngFuture = useMemoized(fetchTempleLatLngMap);

    // ④ useFuture: Future の状態（loading / data / error）を監視する
    final AsyncSnapshot<Map<String, List<TimePlace>>> snapshot = useFuture(timePlaceFuture);
    final AsyncSnapshot<Map<String, TempleLatLng>> templeLatLngSnapshot = useFuture(templeLatLngFuture);

    // ⑤ useEffect: 月が切り替わるたびにデバッグログを出力する副作用
    useEffect(() {
      debugPrint(
        '表示月が変わりました: '
        '${displayMonth.value.year}年${displayMonth.value.month}月',
      );
      return null;
    }, <Object?>[displayMonth.value]);

    void goToPreviousMonth() {
      final DateTime cur = displayMonth.value;
      displayMonth.value = DateTime(cur.year, cur.month - 1);
    }

    void goToNextMonth() {
      final DateTime cur = displayMonth.value;
      displayMonth.value = DateTime(cur.year, cur.month + 1);
    }

    final Map<String, TempleLatLng> templeLatLngMap = templeLatLngSnapshot.data ?? <String, TempleLatLng>{};

    // ダイアログを表示する関数
    void showDayDialog(DateTime date, List<TimePlace> items) {
      final List<TimePlace> sorted = <TimePlace>[...items]
        ..sort((TimePlace a, TimePlace b) => a.time.compareTo(b.time));

      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          // Dialog + SizedBox(maxFinite) で insetPadding(20px) いっぱいに広げる
          return Dialog(
            backgroundColor: _surfaceColor,
            insetPadding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.maxFinite,
              height: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // タイトル
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          '¥${_formatPrice(items.fold(0, (int sum, TimePlace p) => sum + p.price))}',
                          style: TextStyle(fontSize: 15, color: _textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: _borderColor, height: 1),
                  // リスト（スクロール可能）
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: sorted.map((TimePlace item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // 時刻
                                Text(item.time, style: TextStyle(fontSize: 13, color: _textColor.withOpacity(0.6))),
                                const SizedBox(width: 12),
                                // 場所 ＋ 金額
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(item.place, style: const TextStyle(fontSize: 13, color: _textColor)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          if (templeLatLngMap.containsKey(item.place))
                                            Text(
                                              '${templeLatLngMap[item.place]!.lat} / ${templeLatLngMap[item.place]!.lng}',
                                              style: TextStyle(fontSize: 11, color: _textColor.withOpacity(0.5)),
                                            )
                                          else
                                            const SizedBox(),
                                          Text(
                                            '¥${_formatPrice(item.price)}',
                                            style: TextStyle(fontSize: 13, color: _textColor.withOpacity(0.7)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final int rowCount = calendarDays.length ~/ 7;
    const BorderSide borderSide = BorderSide(color: _borderColor);
    final Map<String, List<TimePlace>> timePlaceMap = snapshot.data ?? <String, List<TimePlace>>{};

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── 月ナビゲーション ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  tooltip: '前の月',
                  onPressed: goToPreviousMonth,
                  icon: const Icon(Icons.arrow_back, color: _textColor),
                ),
                Text(
                  '${displayMonth.value.year}年 ${displayMonth.value.month}月',
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  tooltip: '次の月',
                  onPressed: goToNextMonth,
                  icon: const Icon(Icons.arrow_forward, color: _textColor),
                ),
              ],
            ),
          ),

          // ── 曜日ヘッダー＋カレンダーグリッド ─────────────
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // margin(各辺 0.5px → 左右合計 1px)を引いてからセルサイズを計算
              // → 7セル × (cellSize + 1px) = maxWidth になる
              final double cellSize = (constraints.maxWidth - 7) / 7;

              return Column(
                children: <Widget>[
                  // 曜日ヘッダー行
                  Row(
                    // ignore: always_specify_types
                    children: List.generate(7, (int col) {
                      final Color color = col == 0
                          ? _sundayColor
                          : col == 6
                          ? _saturdayColor
                          : _textColor.withOpacity(0.5);
                      return SizedBox(
                        width: cellSize + 1,
                        height: 32,
                        child: Center(
                          child: Text(
                            _weekdayLabels[col],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 1),
                          ),
                        ),
                      );
                    }),
                  ),

                  // カレンダーグリッド（最大 6 行）
                  // ignore: always_specify_types
                  ...List.generate(rowCount, (int row) {
                    return Row(
                      // ignore: always_specify_types
                      children: List.generate(7, (int col) {
                        final DateTime? date = calendarDays[row * 7 + col];
                        final bool isToday =
                            date != null && date.year == now.year && date.month == now.month && date.day == now.day;

                        Color textColor = _textColor;
                        if (col == 0) {
                          textColor = _sundayColor;
                        }
                        if (col == 6) {
                          textColor = _saturdayColor;
                        }

                        final BorderSide activeBorder = isToday
                            ? const BorderSide(color: _todayBorderColor)
                            : borderSide;

                        // Map のキー: {year}-{MM}-{dd}
                        final String? dateKey = date != null
                            ? '${date.year}-'
                                  '${date.month.toString().padLeft(2, '0')}-'
                                  '${date.day.toString().padLeft(2, '0')}'
                            : null;
                        final int count = dateKey != null ? (timePlaceMap[dateKey]?.length ?? 0) : 0;
                        final bool hasTemple =
                            dateKey != null &&
                            (timePlaceMap[dateKey]?.any((TimePlace p) => templeLatLngMap.containsKey(p.place)) ??
                                false);

                        final Widget cell = Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(0.5),
                          decoration: BoxDecoration(
                            border: Border(
                              top: activeBorder,
                              right: activeBorder,
                              bottom: activeBorder,
                              left: activeBorder,
                            ),
                          ),
                          child: date != null
                              ? Stack(
                                  children: <Widget>[
                                    // 左上: 日付
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Text('${date.day}', style: TextStyle(fontSize: 12, color: textColor)),
                                      ),
                                    ),

                                    // 左下: 神社アイコン
                                    if (hasTemple)
                                      const Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: EdgeInsets.all(3),
                                          child: Icon(FontAwesomeIcons.toriiGate, color: Color(0xFFFBB6CE), size: 10),
                                        ),
                                      ),

                                    // 右下: TimePlace の件数
                                    if (count > 0)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text('$count', style: const TextStyle(fontSize: 12, color: _textColor)),

                                              Text(
                                                '¥${_formatPrice(timePlaceMap[dateKey]!.fold(0, (int sum, TimePlace p) => sum + p.price))}',
                                                style: TextStyle(fontSize: 10, color: _textColor.withOpacity(0.6)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        );

                        // count > 0 のセルだけタップ可能にする
                        if (count > 0 && date != null) {
                          return GestureDetector(onTap: () => showDayDialog(date, timePlaceMap[dateKey]!), child: cell);
                        }
                        return cell;
                      }),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
