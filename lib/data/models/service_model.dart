class GarageService {
  final String id;
  final String name;
  final double price;
  final String? description;

  GarageService({
    required this.id,
    required this.name,
    required this.price,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'description': description};
  }

  factory GarageService.fromMap(Map<String, dynamic> map, String id) {
    return GarageService(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'],
    );
  }
}
