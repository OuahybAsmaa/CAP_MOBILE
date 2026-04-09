// ──────────────────────────────────────────────────────────────
//  MODÈLE
// ──────────────────────────────────────────────────────────────
class RfidSseEntry {
  final String uuid;
  final int codeMag;
  final String gencodeRfid;
  final String gencodeCh;
  final String epc;
  final String codeMotif;
  final int codeCollab;
  final DateTime dateCrea;

  const RfidSseEntry({
    required this.uuid,
    required this.codeMag,
    required this.gencodeRfid,
    required this.gencodeCh,
    required this.epc,
    required this.codeMotif,
    required this.codeCollab,
    required this.dateCrea,
  });

  factory RfidSseEntry.fromJson(Map<String, dynamic> json) {
    return RfidSseEntry(
      uuid:        json['uuid']        as String,
      codeMag:     json['codeMag']     as int,
      gencodeRfid: json['gencodeRfid'] as String,
      gencodeCh:   json['gencodeCh']   as String,
      epc:         json['epc']         as String,
      codeMotif:   json['codeMotif']   as String,
      codeCollab:  json['codeCollab']  as int,
      dateCrea:    DateTime.parse(json['dateCrea'] as String).toLocal(),
    );
  }
}