class Voyage {
  final int idVoyage;
  final String nomClient;
  final String phone;
  final String villeDep;
  final String villeArr;
  final DateTime dateDep;
  final int nbrPlace;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  Voyage({
    required this.idVoyage,
    required this.nomClient,
    required this.phone,
    required this.villeDep,
    required this.villeArr,
    required this.dateDep,
    required this.nbrPlace,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Voyage.fromJson(Map<String, dynamic> json) {
    return Voyage(
      idVoyage: json['id_voyage'],
      nomClient: json['nomclient'],
      phone: json['phone'],
      villeDep: json['ville_dep'],
      villeArr: json['ville_arr'],
      dateDep: DateTime.parse(json['date_dep']),
      nbrPlace: (json['nbr_place'] as num).toInt(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convertit une liste JSON en List<Voyage>
  static List<Voyage> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => Voyage.fromJson(json)).toList();
  }
}
