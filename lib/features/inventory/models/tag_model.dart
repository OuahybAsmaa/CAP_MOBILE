class TagModel {
  final String epc;
  final int count;
  final double rssi;
  final String memoryBankData;
  final String tidData;

  const TagModel({
    required this.epc,
    required this.count,
    required this.rssi,
    this.memoryBankData = '',
    this.tidData = '',
  });


  TagModel copyWithNewRead(
      double newRssi, {
        String memoryBankData = '',
        String tidData = '',
      }) {
    return TagModel(
      epc: epc,
      count: count + 1,
      rssi: newRssi,
      memoryBankData:
      memoryBankData.isNotEmpty ? memoryBankData : this.memoryBankData,
      tidData: tidData.isNotEmpty ? tidData : this.tidData,
    );
  }

  /// Affichage formaté du RSSI
  String get rssiDisplay => '${rssi.toStringAsFixed(0)} dBm';
}