class EpcCalculator {

  // ── NOUVEAU : construit l'EPC usine à partir du sériel décimal imprimé ──
  // Header fixe : 3034 + 10 zéros + sériel en hex (10 chars)
  static String buildFactoryEpc(String serialDecimal) {
    final serialInt = int.parse(serialDecimal);
    final serialHex = serialInt.toRadixString(16).toUpperCase().padLeft(10, '0');
    return '3034' '0000000000' + serialHex;
    // = 4 + 10 + 10 = 24 chars hex = 96 bits ✓
  }

  // ── NOUVEAU : extrait le sériel hex depuis un EPC usine calculé ──
  // (remplace extractSerialFromEpc qui lisait depuis la puce)
  static String extractSerialHexFromFactoryEpc(String factoryEpc) {
    return factoryEpc.substring(factoryEpc.length - 10);
  }

  static String buildEpcFromGtin(String gtin, String serialHex) {
    final companyStr = gtin.substring(1, 7);
    final sg1Code    = gtin.substring(7, 13);
    return _buildEpcFromParts(companyStr, sg1Code, serialHex);
  }

  static String _buildEpcFromParts(
      String companyStr, String sg1Code, String serialHex) {
    final header    = '00110000';
    final filter    = '001';
    final partition = '110';
    final company   = _toBinary(int.parse(companyStr), 20);
    final sg1Binary = _toBinary(int.parse(sg1Code),    24);
    final serialBin = _hexToBinary(serialHex, 38);

    final fullBinary =
        header + filter + partition + company + sg1Binary + serialBin;

    return _binaryToHex(fullBinary);
  }

  // Ancienne méthode conservée au cas où (mais plus utilisée dans le flux principal)
  static String extractSerialFromEpc(String factoryEpc) {
    return factoryEpc.substring(factoryEpc.length - 10);
  }

  static String _toBinary(int value, int bits) =>
      value.toRadixString(2).padLeft(bits, '0');

  static String _hexToBinary(String hex, int bits) =>
      _toBinary(int.parse(hex, radix: 16), bits);

  static String _binaryToHex(String binary) {
    final buffer = StringBuffer();
    for (int i = 0; i < binary.length; i += 4) {
      final nibble = binary.substring(i, i + 4);
      buffer.write(
        int.parse(nibble, radix: 2).toRadixString(16).toUpperCase(),
      );
    }
    return buffer.toString();
  }
}