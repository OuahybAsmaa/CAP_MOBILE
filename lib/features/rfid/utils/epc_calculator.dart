class EpcCalculator {

  static String buildEpcFromGtin(String gtin, String serialHex) {
    final companyStr = gtin.substring(1, 7);
    final sg1Code    = gtin.substring(7, 13);
    return _buildEpcFromParts(companyStr, sg1Code, serialHex);
  }
/*
  static String buildEpc(String sg1Code, String serialHex) {
    return _buildEpcFromParts('361758', sg1Code, serialHex);
  }
*/
  static String _buildEpcFromParts(
      String companyStr, String sg1Code, String serialHex) {
    final header    = '00110000';                          // 8 bits
    final filter    = '001';                               // 3 bits
    final partition = '110';                               // 3 bits
    final company   = _toBinary(int.parse(companyStr), 20); // 20 bits
    final sg1Binary = _toBinary(int.parse(sg1Code),    24); // 24 bits
    final serialBin = _hexToBinary(serialHex, 38);          // 38 bits

    final fullBinary =
        header + filter + partition + company + sg1Binary + serialBin;

    // Total = 8+3+3+20+24+38 = 96 bits = 24 chars hex
    return _binaryToHex(fullBinary);
  }


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