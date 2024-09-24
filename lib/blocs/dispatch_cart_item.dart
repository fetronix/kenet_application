class DispatchCartItem {
  final String assetName;
  final String serialNumber;
  final String tagNumber;
  final String location;
  final String receivedName; // New field added

  DispatchCartItem({
    required this.assetName,
    required this.serialNumber,
    required this.tagNumber,
    required this.location,
    required this.receivedName, // Include new field in constructor
  });

  // Override toString for better debugging
  @override
  String toString() {
    return 'DispatchCartItem(assetName: $assetName, serialNumber: $serialNumber, tagNumber: $tagNumber, location: $location, receivedName: $receivedName)';
  }

  // Override equality and hashCode for proper comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DispatchCartItem &&
        other.assetName == assetName &&
        other.serialNumber == serialNumber &&
        other.tagNumber == tagNumber &&
        other.location == location &&
        other.receivedName == receivedName; // Include new field in comparison
  }

  @override
  int get hashCode {
    return assetName.hashCode ^
    serialNumber.hashCode ^
    tagNumber.hashCode ^
    location.hashCode ^
    receivedName.hashCode; // Include new field in hashCode
  }

  // Convert DispatchCartItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'asset_name': assetName,
      'serial_number': serialNumber,
      'tag_number': tagNumber,
      'location': location,
      'received_by_name': receivedName, // Include new field in map
    };
  }

  // Create a DispatchCartItem from a Map
  factory DispatchCartItem.fromMap(Map<String, dynamic> map) {
    return DispatchCartItem(
      assetName: map['asset_name'],
      serialNumber: map['serial_number'],
      tagNumber: map['tag_number'],
      location: map['location'],
      receivedName: map['received_by_name'], // Include new field in factory constructor
    );
  }
}
