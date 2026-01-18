class CattleModel {
  final String id;
  final String type; // 'cow', 'goat', 'buffalo'
  final String breed;
  final int age;
  final DateTime? addedAt;

  CattleModel({
    required this.id,
    required this.type,
    required this.breed,
    required this.age,
    this.addedAt,
  });

  factory CattleModel.fromJson(Map<String, dynamic> json, String id) {
    return CattleModel(
      id: id,
      type: json['cattle'] ?? '', // Note: React Native code used 'cattle' for type
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      addedAt: json['addedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cattle': type,
      'breed': breed,
      'age': age,
      'addedAt': addedAt ?? DateTime.now(),
    };
  }
}
