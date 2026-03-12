class Bagage {
  final int voyageId;
  final String type;
  final int nombre;

  Bagage({required this.voyageId, required this.type, required this.nombre});

  Map<String, dynamic> toJson() {
    return {"voyage_id": voyageId, "type": type, "nombre": nombre};
  }
}
