class RfidReaderModel {
  final String name;
  final String address;

  RfidReaderModel({
    required this.name,
    required this.address,
  });

  factory RfidReaderModel.fromMap(Map<String, String> map) {
    return RfidReaderModel(
      name:    map['name']    ?? 'Inconnu',
      address: map['address'] ?? 'N/A',
    );
  }
}