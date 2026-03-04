import 'dart:convert';
import 'package:http/http.dart' as http;

class TempleLatLng {
  const TempleLatLng({
    required this.id,
    required this.temple,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rank,
  });

  factory TempleLatLng.fromJson(Map<String, dynamic> json) {
    return TempleLatLng(
      id: json['id'] as int,
      temple: json['temple'] as String,
      address: json['address'] as String,
      lat: json['lat'] as String,
      lng: json['lng'] as String,
      rank: json['rank'] as String,
    );
  }

  final int id;
  final String temple;
  final String address;
  final String lat;
  final String lng;
  final String rank;
}

/// API からデータを取得し、temple をキーにした Map を返す
Future<Map<String, TempleLatLng>> fetchTempleLatLngMap() async {
  final http.Response response = await http.get(Uri.parse('http://49.212.175.205:8082/api/temple-latlng'));

  if (response.statusCode != 200) {
    throw Exception('API エラー: ${response.statusCode}');
  }

  final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
  final Map<String, TempleLatLng> map = <String, TempleLatLng>{};
  for (final dynamic e in jsonList) {
    final TempleLatLng item = TempleLatLng.fromJson(e as Map<String, dynamic>);
    map[item.temple] = item;
  }
  return map;
}
