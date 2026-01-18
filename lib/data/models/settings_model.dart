class GarageSettings {
  final String garageName;
  final String address;
  final String contactNumber;
  final bool gstEnabled;
  final double gstPercentage;
  final String currencySymbol;
  final String themeMode; // 'light', 'dark', 'system'

  GarageSettings({
    this.garageName = 'AutoCare Pro',
    this.address = '',
    this.contactNumber = '',
    this.gstEnabled = false,
    this.gstPercentage = 18.0,
    this.currencySymbol = '₹',
    this.themeMode = 'system',
  });

  Map<String, dynamic> toMap() {
    return {
      'garageName': garageName,
      'address': address,
      'contactNumber': contactNumber,
      'gstEnabled': gstEnabled,
      'gstPercentage': gstPercentage,
      'currencySymbol': currencySymbol,
      'themeMode': themeMode,
    };
  }

  factory GarageSettings.fromMap(Map<String, dynamic> map) {
    return GarageSettings(
      garageName: map['garageName'] ?? 'AutoCare Pro',
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      gstEnabled: map['gstEnabled'] ?? false,
      gstPercentage: (map['gstPercentage'] ?? 18.0).toDouble(),
      currencySymbol: map['currencySymbol'] ?? '₹',
      themeMode: map['themeMode'] ?? 'system',
    );
  }
}
