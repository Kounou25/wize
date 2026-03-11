import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voyage.dart'; // Assurez-vous d'importer le modèle Voyage

class VoyageService {
  final String baseUrl = "http://168.231.83.47:7000/voyages/phone/";

  // Retourne une liste de voyages pour un même numéro
  Future<List<Voyage>> getVoyages(String phone) async {
    final url = Uri.parse('$baseUrl$phone');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Si c'est une liste de Map<dynamic,dynamic>, on cast en Map<String,dynamic>
        if (jsonData is List) {
          return jsonData
              .map((e) => Voyage.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (jsonData is Map) {
          return [Voyage.fromJson(Map<String, dynamic>.from(jsonData))];
        } else {
          return [];
        }
      } else {
        print("Erreur ${response.statusCode}: ${response.reasonPhrase}");
        return [];
      }
    } catch (e) {
      print("Erreur lors de la requête: $e");
      return [];
    }
  }
}
