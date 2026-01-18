class InventoryItem {
  final String id;
  final String name;
  final String category; // Engine, Electrical, Body, Accessories
  final String brand;
  final int quantity;
  final double purchasePrice;
  final double price; // Selling Price
  final int lowStockThreshold;
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock'
  final String? imageUrl; // Image URL for the spare part
  final String? vehicleType; // Car, Bike, Truck

  InventoryItem({
    required this.id,
    required this.name,
    this.category = 'General',
    this.brand = '',
    required this.quantity,
    required this.purchasePrice,
    required this.price,
    this.lowStockThreshold = 5,
    this.status = 'In Stock',
    this.imageUrl,
    this.vehicleType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'brand': brand,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'price': price,
      'lowStockThreshold': lowStockThreshold,
      'status': status,
      'imageUrl': imageUrl,
      'vehicleType': vehicleType,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'General',
      brand: map['brand'] ?? '',
      quantity: map['quantity'] ?? 0,
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      status: map['status'] ?? 'In Stock',
      imageUrl: map['imageUrl'],
      vehicleType: map['vehicleType'],
    );
  }
}
