import 'dart:convert';
import 'package:http/http.dart' as http;

class TimePlace {
  const TimePlace({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.ymd,
    required this.time,
    required this.place,
    required this.price,
    this.createdAt,
  });

  factory TimePlace.fromJson(Map<String, dynamic> json) {
    return TimePlace(
      id: json['id'] as int,
      year: json['year'] as String,
      month: json['month'] as String,
      day: json['day'] as String,
      ymd: json['ymd'] as String,
      time: json['time'] as String,
      place: json['place'] as String,
      price: json['price'] as int,
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String year;
  final String month;
  final String day;
  final String ymd;
  final String time;
  final String place;
  final int price;
  final String? createdAt;
}

/// API からデータを取得し、{year}-{month}-{day} をキーにした Map を返す
Future<Map<String, List<TimePlace>>> fetchTimePlaceMap() async {
  final http.Response response = await http.get(Uri.parse('http://49.212.175.205:8082/api/timeplace'));

  if (response.statusCode != 200) {
    throw Exception('API エラー: ${response.statusCode}');
  }

  final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
  // ignore: always_specify_types
  final List<TimePlace> items = jsonList.map((e) => TimePlace.fromJson(e as Map<String, dynamic>)).toList();

  final Map<String, List<TimePlace>> map = <String, List<TimePlace>>{};
  for (final TimePlace item in items) {
    final String key = '${item.year}-${item.month}-${item.day}';
    map.putIfAbsent(key, () => <TimePlace>[]).add(item);
  }
  return map;
}
