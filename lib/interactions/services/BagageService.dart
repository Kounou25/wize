import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bagage.dart';

class BagageService {
  static const String baseUrl = "http://168.231.83.47:7000/lunggages";

  /// Envoie un ou plusieurs bagages en une seule requête
  static Future<bool> createBagages(List<Bagage> bagages) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"bagages": bagages.map((b) => b.toJson()).toList()}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      print("Erreur API bagages : ${response.body}");
      return false;
    } catch (e) {
      print("Erreur HTTP bagages : $e");
      return false;
    }
  }
}
