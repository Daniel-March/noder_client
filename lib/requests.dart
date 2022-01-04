import 'dart:convert';

import 'package:http/http.dart' as http;

class Requests{
  // static String ip = "10.0.2.2:8000";
  static String ip = "80.78.245.197:8000";
  static Future<String> uploadCluster(Map cluster) async{
    Uri uri = Uri.parse("http://$ip/share");

    final response = await http.post(uri, headers: {
      "Accept": "application/json",
      "Access-Control_Allow_Origin": "*",
      "Access-Control-Allow-Headers": "Access-Control-Allow-Origin, Accept",
      "Content-Type": "application/json"
    }, body: jsonEncode({"cluster": cluster}));
    print(response.body);
    return response.body;
  }
  static Future<Map?> downloadCluster(String token) async{
    Uri uri = Uri.parse("http://$ip/get");

    final response = await http.post(uri, headers: {
      "Accept": "application/json",
      "Access-Control_Allow_Origin": "*",
      "Access-Control-Allow-Headers": "Access-Control-Allow-Origin, Accept",
      "Content-Type": "application/json"
    }, body: jsonEncode({"token": token}));

    if(response.statusCode==400) {
      return null;
    }
    return jsonDecode(response.body);
  }
}