/// Modèle représentant un tag RFID lu lors d'un inventaire.
/// Placez ce fichier dans : features/inventory/models/tag_model.dart
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

  /// Crée une copie mise à jour lors d'une nouvelle lecture du même tag.
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

  /// Affichage formaté du RSSI (ex: -65 dBm)
  String get rssiDisplay => '${rssi.toStringAsFixed(0)} dBm';
}